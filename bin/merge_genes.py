import pandas as pd
import argparse

parser = argparse.ArgumentParser()

parser.add_argument('-hum', '--human_genes')   
parser.add_argument('-vir', '--viral_genes')   
args = parser.parse_args()

human_genes = pd.read_csv(args.human_genes)
viral_genes = pd.read_csv(args.viral_genes)

human_genes.rename(columns={human_genes.columns[0]: "GeneID"}, inplace=True)
viral_genes.rename(columns={viral_genes.columns[0]: "GeneID"}, inplace=True)

merge_genes = pd.concat([human_genes, viral_genes], axis=0)
merge_genes.fillna(0, inplace=True)

print(merge_genes.head())

merge_genes.to_csv("merged_genes.csv",index=False)