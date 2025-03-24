import pandas as pd
import argparse

parser = argparse.ArgumentParser()

parser.add_argument('-hum', '--human_count')   
parser.add_argument('-vir', '--viral_count')   
args = parser.parse_args()

human_count = pd.read_csv(args.human_count)
viral_count = pd.read_csv(args.viral_count)

merge_count = pd.concat([human_count, viral_count], axis=0)
merge_count.fillna(0, inplace=True)
merge_count.set_index('Geneid', inplace=True)
merge_count.drop(columns=['gene_name'], inplace=True)
merge_count.to_csv("merged_count.csv")