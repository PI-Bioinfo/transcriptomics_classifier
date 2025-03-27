import pandas as pd
import argparse

parser = argparse.ArgumentParser()

parser.add_argument('-me', '--meta') 
parser.add_argument('-hum', '--human_count')   
parser.add_argument('-vir', '--viral_count')   

args = parser.parse_args()

meta = args.meta
human_count = pd.read_csv(args.human_count)
viral_count = pd.read_csv(args.viral_count)

print(viral_count.head())

human_count.rename(columns={human_count.columns[0]: "GeneID"}, inplace=True)
viral_count.rename(columns={viral_count.columns[0]: "GeneID"}, inplace=True)

merge_count = pd.concat([human_count, viral_count], axis=0)
merge_count.fillna(0, inplace=True)

print(merge_count.head())

merge_count.to_csv(f"{meta}_merged_count.csv",index=False)