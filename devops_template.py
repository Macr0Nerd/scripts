import argparse
import contextlib
import json
import logging
import sys


logger = logging.getLogger(__name__)


def arguments() -> dict:
    """create parameters and parse arguments

    :return: script arguments
    :rtype: dict
    """
    parser = argparse.ArgumentParser(
        prog='devops_template.py',
        description='template script for developer operations tasks',
        epilog='Developed by Gabriele Ron (gron@groncyber.com)'
    )


    parser_output = parser.add_argument_group(title='output arguments')
    parser_output.add_argument('-o', '--outfile', help='output to a file')

    parser_output_format = parser_output.add_mutually_exclusive_group()
    parser_output_format.add_argument('--text', help='output a Python dict',
                                      action='store_const', const='text', dest='format')
    parser_output_format.add_argument('--json', help='output in JSON format',
                                      action='store_const', const='json', dest='format')

    parser_logging = parser.add_argument_group(title='logging arguments')
    parser_logging.add_argument('-v', '--verbose', help='get verbose output', action='count', default=0)
    parser_logging.add_argument('-q', '--quiet', help='suppress output', action='count', default=0)

    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(1)

    args = vars(parser.parse_args())

    if not args.get('format'):
        args['format'] = 'text'

    return args


def generate_output(data: dict, *, outfile: str = None, format: str = None, **_) -> int:
    """generate and write output of dependency data

    :param data: data
    :type data: dict
    :param outfile: output file
    :type outfile: str
    :param format: output format
    :type format: str
    :return: exit code
    :rtype: int
    """
    if not format:
        format = 'text'

    out = ''
    flags = 'w'

    if format == 'text':
        out = str(data)
    elif format == 'json':
        out = json.dumps(data)

    try:
        with open(outfile, flags) if outfile else contextlib.nullcontext(sys.stdout) as f:
            f.write(out)
    except FileNotFoundError as exc:
        logger.error(exc)
        return exc.errno

    return 0


def main() -> int:
    args = arguments()

    if verbose := args.get('verbose'):
        if verbose >= 2:
            logger.setLevel(logging.DEBUG)
        else:
            logger.setLevel(logging.INFO)
    elif quiet := args.get('quiet'):
        if quiet >= 2:
            logger.setLevel(logging.FATAL)
        else:
            logger.setLevel(logging.ERROR)
    else:
        logger.setLevel(logging.WARNING)

    logger.debug('args: %s', args)

    data = {}
    ret = generate_output(data, **args)

    return ret


if __name__ == '__main__':
    logging.basicConfig(format="[%(asctime)s] %(levelname)s -- %(message)s")
    sys.exit(main())
