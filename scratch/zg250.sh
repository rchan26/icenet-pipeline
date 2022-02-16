#!/usr/bin/env python

if __name__ == "__main__":
    import logging
    import pandas as pd

    logging.basicConfig(level=logging.DEBUG)

    from icenet2.data.interfaces.cds import ERA5Downloader

    era5 = ERA5Downloader(
        var_names=["zg"],
        pressure_levels=[[250,500]],
        dates=[pd.to_datetime(date).date() for date in
               pd.date_range("1990-1-1", "1999-12-31",
                             freq="D")],
        delete_tempfiles=True,
        max_threads=32,
        north=False,
        south=True,
        use_toolbox=True,
    )
    era5.download()
    era5.regrid()

