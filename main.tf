
# Criação do bucket S3 para a guarda dos dados
resource "aws_s3_bucket" "athena_bucket" {
  bucket = var.bucket_name
  acl    = "private"
  force_destroy = true

  tags = {
    Name  = "Prova - Desafio Maxmilhas"
    Squad = "Dados"
  }
}

# Inclusão do arquivo pesquisas.csv no diretório source no Bucket S3
resource "aws_s3_bucket_object" "object" {

  bucket = var.bucket_name
  key    = "/source/pesquisas.csv"
  source = "../desafio/pesquisas.csv"
  force_destroy = true

  depends_on = [aws_s3_bucket.athena_bucket]
}

# Criando o workgroup pra o Athena
resource "aws_athena_workgroup" "maxmilhas_desafio" {
  name = var.workgroup

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = false

    result_configuration {
      output_location = format("s3://%s/outputs/",var.bucket_name)
    }
  }
}

# Criação do banco de dados no Athena
resource "aws_athena_database" "athena_db" {
  name   = var.database_name
  bucket = aws_s3_bucket.athena_bucket.bucket
}

# Criação da Tabela no Glue para ser visualizada no Athena
resource "aws_glue_catalog_table" "aws_glue_catalog_table" {
  name          = var.glue_catalog_table
  database_name = var.database_name
  depends_on = [aws_athena_database.athena_db]

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
  }

  storage_descriptor {
    location      = format("s3://%s/source/",var.bucket_name)
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = var.glue_catalog_table
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"

      parameters = {
        "serialization.format" = ","
        "field.delim"          = ","
      }
    }

    columns {
      name = "airport_to"
      type = "string"
    }

    columns {
      name = "buscou"
      type = "int"
    }

    columns {
      name = "comprou"
      type = "int"
    }
  }
}

# Criação da Query para ser executada no Athena
resource "aws_athena_named_query" "my_query" {
  name     = "query_desafio"
  database = var.database_name
  workgroup = var.workgroup
  query =  format("SELECT DISTINCT airport_to,SUM(buscou) AS total_buscas,SUM(comprou) AS total_compras FROM \"%s\".\"%s\" WHERE comprou <> 0 AND buscou <> 0 GROUP BY airport_to;",var.database_name, var.glue_catalog_table)

  depends_on = [aws_glue_catalog_table.aws_glue_catalog_table]
}

# Configurando a role para aplicar as permissões para função Lambda
resource "aws_iam_role" "lambda_athena_query" {
  name = "lambda_athena_query"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Criando a polítca para as permissões da Lambda
resource "aws_iam_policy" "lambda_athena_query_access" {
  name        = "lambda_athena_query_access"
  path        = "/"
  description = "IAM policy for grant permission to lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "*",
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Anexando a política criada na role para a função Lambda
resource "aws_iam_role_policy_attachment" "lambda_athena_permission" {
  role       = aws_iam_role.lambda_athena_query.name
  policy_arn = aws_iam_policy.lambda_athena_query_access.arn
}

# Criando a função Lambda
resource "aws_lambda_function" "lambda_athena_query" {
  filename      = "lambda_function.zip"
  function_name = "lambda_athena_query"
  role          = aws_iam_role.lambda_athena_query.arn
  handler       = "lambda_function.lambda_handler"

  source_code_hash = filebase64sha256("lambda_function.zip")

  runtime = "python2.7"

  depends_on = [aws_glue_catalog_table.aws_glue_catalog_table]

}

# Chamando a função Lambda
data "aws_lambda_invocation" "my_lambda_function" {
  function_name = aws_lambda_function.lambda_athena_query.function_name

  input = <<JSON
{

}
JSON

depends_on = [aws_glue_catalog_table.aws_glue_catalog_table]

}

# Retorno da execução da função Lambda
output "result" {
  value       = data.aws_lambda_invocation.my_lambda_function.result
}
