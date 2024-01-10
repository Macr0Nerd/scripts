import argparse
import contextlib
import importlib.metadata
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
        epilog='Developed by Gabriele Ron (developer@groncyber.com)'
    )


    parser_output = parser.add_argument_group(title='output arguments')
    parser_output.add_argument('-o', '--outfile', help='output to a file')

    parser_output_format = parser_output.add_mutually_exclusive_group()
    parser_output_format.add_argument('--csv', help='output in CSV format',
                                      action='store_const', const='csv', dest='format')
    parser_output_format.add_argument('--json', help='output in JSON format',
                                      action='store_const', const='json', dest='format')
    parser_output_format.add_argument('--pandas-parquet', help='output a Pandas dataframe to a parquet',
                                      action='store_const', const='pandas-parquet', dest='format')
    parser_output_format.add_argument('--python', help='output a Python dict',
                                      action='store_const', const='python', dest='format')
    parser_output_format.add_argument('--text', help='output in a human readable format',
                                      action='store_const', const='text', dest='format')

    parser_logging = parser.add_argument_group(title='logging arguments')
    parser_logging.add_argument('-v', '--verbose', help='get verbose output', action='count', default=0)
    parser_logging.add_argument('-q', '--quiet', help='suppress output', action='count', default=0)

    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(1)

    args = vars(parser.parse_args())

    if not args.get('format'):
        args['format'] = 'text'
    elif args['format'] in ['csv', 'pandas-parquet']:
        try:
            pandas_version = importlib.metadata.version('pandas')
            logger.info('Found Pandas version %s', pandas_version)
        except importlib.metadata.PackageNotFoundError as exc:
            logger.error('Pandas output was specified, but Pandas is not available')
            sys.exit(1)

        if args['format'] == 'pandas-parquet':
            try:
                parquet_version = importlib.metadata.version('pyarrow')
                logger.info('Found PyArrow version %s', parquet_version)
            except importlib.metadata.PackageNotFoundError as exc:
                try:
                    parquet_version = importlib.metadata.version('fastparquet')
                    logger.info('Found FastParquet version %s', parquet_version)
                except importlib.metadata.PackageNotFoundError as exc:
                    logger.error('Pandas parquet output was specified, but no parquet backend was found')
                    sys.exit(1)

            if not args.get('outfile'):
                logger.error('Pandas-parquet format requires an output file to be specified')
                sys.exit(1)

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

    # This allows for the file to be written as a string or binary, that way it can handle
    # data like parquets. NOTE: sys.stdout __cannot__ accept binary so you must check that
    # you're not writing to sys.stdout.
    flags = 'w'

    if format == 'text':
        out = str(data)
    elif format == 'json':
        out = json.dumps(data)
    elif format == 'pandas-parquet':
        from pandas import DataFrame

        rows = []
        for k, v in data.items():
            rows.append(v)

        df = DataFrame.from_dict(rows)
        if format == 'csv':
            out = df.to_csv()
        elif format == 'pandas-parquet':
            flags += 'b'
            out = df.to_parquet()

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
