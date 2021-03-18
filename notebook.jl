### A Pluto.jl notebook ###
# v0.12.21

using Markdown
using InteractiveUtils

# ╔═╡ d5eed996-861b-11eb-0795-1999587b65b1
begin
	using Pkg
	Pkg.add("PlutoUI")
	Pkg.add("HTTP")
	Pkg.add("Parquet")
	Pkg.add("StatsModels")
	Pkg.add("Arrow")
	Pkg.activate(".")
	import CSV, DataFrames, Dates, StatsPlots, StatsModels, Statistics
	import DataFrames.DataFrame
	using Plots, PlutoUI, HTTP, DelimitedFiles, Parquet, Arrow
end

# ╔═╡ 12493182-861c-11eb-170f-794bd640d3f3
begin
	df = CSV.read("temp.csv", DataFrame)
	write_parquet("data_file.parquet", df)
	df = DataFrame(read_parquet("data_file.parquet"))
	Arrow.write("data_file.arrow", df)
	df = DataFrame(Arrow.Table("data_file.arrow"))
end

# ╔═╡ deb2d0ec-8699-11eb-2d31-6f3caeb706e5
begin
	dates = names(df)[5:end]
	countries = unique(df[:, :"Country/Region"])
end

# ╔═╡ 18d5fe2e-86bc-11eb-2260-db09a712ffd3
# begin
# 	data_by_country = DataFrames.combine(DataFrames.groupby(df, "Country/Region"), dates .=> sum .=> dates)
# end

# ╔═╡ 8d52c562-86c5-11eb-3790-39e5509ebf4f
# data_by_country

# ╔═╡ db696724-8765-11eb-3be2-d775f5fb8a25
begin
	algeria = df[df."Country/Region" .== "Algeria", 4:end]
	
	for i = 4:size(algeria, 2)
    	if eltype(algeria[!, i]) == String
        	algeria[!, i] = parse.(Float64, algeria[!, i])
    	end
	end
	
	Statistics.mean(eachcol(algeria))
end

# ╔═╡ Cell order:
# ╠═d5eed996-861b-11eb-0795-1999587b65b1
# ╠═12493182-861c-11eb-170f-794bd640d3f3
# ╠═deb2d0ec-8699-11eb-2d31-6f3caeb706e5
# ╠═18d5fe2e-86bc-11eb-2260-db09a712ffd3
# ╠═8d52c562-86c5-11eb-3790-39e5509ebf4f
# ╠═db696724-8765-11eb-3be2-d775f5fb8a25
