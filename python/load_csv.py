import pandas as pd, glob, os, getpass
from urllib.parse import quote_plus
from sqlalchemy import create_engine

pw = quote_plus(getpass.getpass("MySQL password: "))
eng = create_engine(f"mysql+pymysql://root:{pw}@localhost/olist")

for f in sorted(glob.glob("data/*.csv")):
    name = "stg_" + os.path.basename(f).replace("olist_", "").replace("_dataset", "").replace(".csv", "")
    df = pd.read_csv(f)
    df.to_sql(name, eng, if_exists="replace", index=False, chunksize=5000)
    print(name, len(df), "rows")
