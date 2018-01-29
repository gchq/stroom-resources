"""Asks the user questions and then builds a stack file in YAML,
 ready for user with docker-compose."""

import stack_yaml
import stack_script

if __name__ == "__main__":
    SERVICE_LIST = [
        'stroom', 'stroomDb', 'stroomAuthService', 'stroomAuthUi',
        'stroomAuthDb', 'stroomStats', 'stroomStatsDb', 'stroomProxy',
        'stroomAnnotationsService', 'stroomAnnotationsUi',
        'stroomAnnotationsDb', 'stroomQueryElasticService',
        'stroomQueryElasticUi', 'zookeeper', 'nginx', 'kafka', 'kibana',
        'hdfs', 'hbase', 'elasticsearch', 'fakeSmtp'
    ]

    SERVICES = []
    STACK_TYPE = stack_yaml.prompt_for_stack_type()

    if STACK_TYPE == 'Full':
        SERVICES = SERVICE_LIST

    elif STACK_TYPE == 'Core':
        SERVICES = [
            'stroom', 'stroomDb', 'stroomAuthService', 'stroomAuthUi',
            'stroomAuthDb', 'stroomStatsDb', 'nginx'
        ]
    elif STACK_TYPE == 'Custom':
        SERVICES = stack_yaml.prompt_for_services(SERVICE_LIST)

    STACK_NAME = stack_yaml.prompt_for_stack_name()
    stack_yaml.write_out_yaml(STACK_NAME, SERVICES)

    stack_script.write_out_script(STACK_NAME)
