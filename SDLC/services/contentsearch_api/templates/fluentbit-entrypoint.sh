echo -n 'AWS for Fluent Bit Container Image Version ' &&

cat /AWS_FOR_FLUENT_BIT_VERSION &&

{
  echo '@INCLUDE /fluent-bit/etc/fluent-bit.conf' &&
  echo &&
  echo ${fluent_bit_config}
} > /fluent-bit/etc/main-fluent-bit.conf &&

export ECS_TASK_ID=$(grep -Po -m 1 '^\\s+Record\\s+ecs_task_arn\\s+arn:aws:ecs:.*/\\K[^/]+(?=\\s*$)' /fluent-bit/etc/fluent-bit.conf) &&

exec /fluent-bit/bin/fluent-bit -e /fluent-bit/firehose.so -e /fluent-bit/cloudwatch.so -e /fluent-bit/kinesis.so -c /fluent-bit/etc/main-fluent-bit.conf