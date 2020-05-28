FROM amazon/aws-cli

RUN yum install jq -y

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
