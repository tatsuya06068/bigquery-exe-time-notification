FROM hashicorp/terraform:1.6 as terraform

FROM google/cloud-sdk:440.0.0-alpine

COPY --from=terraform /bin/terraform /usr/local/bin/terraform

RUN apk --update add \
      vim

# https://github.com/gruntwork-io/terragrunt/releases
RUN curl -L "https://github.com/gruntwork-io/terragrunt/releases/download/v0.36.7/terragrunt_linux_amd64" -o /usr/local/bin/terragrunt \
    && chmod +x /usr/local/bin/terragrunt