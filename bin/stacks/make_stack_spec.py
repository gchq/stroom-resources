"""Asks the user questions and then builds a stack file in YAML,
 ready for user with docker-compose."""

import inquirer

def prompt_for_stack_type():
    """Prompts for a stack type."""
    stack_type_question = [
        inquirer.List(
            'stackType',
            message="What sort of stack would you like?",
            choices=['Core', 'Full', 'Custom'],
        ),
    ]
    return inquirer.prompt(stack_type_question)['stackType']


def prompt_for_services(service_list):
    """Prompts for a list of custom services"""
    custom_stack_question = [
        inquirer.Checkbox(
            'services',
            message="What services do you want in your new stack?",
            choices=service_list,
        ),
    ]
    return inquirer.prompt(custom_stack_question)['services']


def prompt_for_stack_name():
    """Prompts for a stack name"""
    stack_name_question = [
        inquirer.Text(
            'stackName', message='What do you want your stack to be called?')
    ]
    return inquirer.prompt(stack_name_question)['stackName']


def build_stack(name, services_to_include):
    """Builds a stack file in YAML format"""
    output_file_name = name + '.yml'

    with open(output_file_name, 'w') as outfile:
        outfile.write('version: \'2.1\'\n\n')
        outfile.write('services:\n\n')
        for fname in services_to_include:
            with open('../compose/containers/' + fname + '.yml') as infile:
                for line in infile:
                    if 'version: \'2.1\'' not in line \
                    and 'services:' not in line \
                    and str.strip(line):
                        outfile.write(line)
            outfile.write('\n\n')


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
    STACK_TYPE = prompt_for_stack_type()

    if STACK_TYPE == 'Full':
        SERVICES = SERVICE_LIST

    elif STACK_TYPE == 'Core':
        SERVICES = [
            'stroom', 'stroomDb', 'stroomAuthService', 'stroomAuthUi',
            'stroomAuthDb', 'stroomStatsDb', 'nginx'
        ]
    elif STACK_TYPE == 'Custom':
        SERVICES = prompt_for_services(SERVICE_LIST)

    STACK_NAME = prompt_for_stack_name()
    build_stack(STACK_NAME, SERVICES)
