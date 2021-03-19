### A Pluto.jl notebook ###
# v0.12.21

using Markdown
using InteractiveUtils

# ╔═╡ d5eed996-861b-11eb-0795-1999587b65b1
begin
	using Pkg
	Pkg.add("PlutoUI")
	Pkg.add("Parquet")
	Pkg.add("StatsBase")
	Pkg.add("StatsModels")
	Pkg.add("Missings")
	Pkg.add("Arrow")
	Pkg.activate(".")
	import CSV, DataFrames, Dates, StatsPlots, StatsModels, Statistics, Missings
	import DataFrames.DataFrame, StatsBase, Base
	using Plots, PlutoUI, DelimitedFiles, Parquet, Arrow
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


# ╔═╡ 8d52c562-86c5-11eb-3790-39e5509ebf4f
unique(DataFrames.describe(df).eltype)

# ╔═╡ db696724-8765-11eb-3be2-d775f5fb8a25
begin
    algeria = df[df."Country/Region" .== "Algeria", begin:end-4]
	
	for i = 1:size(algeria, 2)
		if eltype(algeria[!, i]) .!= Float64
			algeria[!, i] = float.(algeria[!, i])
		end
	end
end

# ╔═╡ 128d315c-8862-11eb-21f4-6bc6e17c250d
function get_nation_stats(nation)
	nation_to_analyze = df[df."Country/Region" .== nation, begin:end-4]
	
	for i = 1:size(nation_to_analyze, 2)
		if eltype(nation_to_analyze[!, i]) .!= Float64
			nation_to_analyze[!, i] = float.(nation_to_analyze[!, i])
		end
	end
	
	Print("\rMean of COVID-19 contractions in " * nation * ": " * string(Statistics.mean(eachcol(algeria))) * "\nMedian of COVID-19 contractions in " * nation * ": " * string(Statistics.median(eachcol(algeria))) * "\nMode of COVID-19 contractions in " * nation * ": " * string(StatsBase.mode(eachcol(algeria))))
	
end

# ╔═╡ 9d6df616-8863-11eb-063d-77661d37a5b2
get_nation_stats("Algeria")

# ╔═╡ Cell order:
# ╠═d5eed996-861b-11eb-0795-1999587b65b1
# ╠═12493182-861c-11eb-170f-794bd640d3f3
# ╠═deb2d0ec-8699-11eb-2d31-6f3caeb706e5
# ╟─18d5fe2e-86bc-11eb-2260-db09a712ffd3
# ╠═8d52c562-86c5-11eb-3790-39e5509ebf4f
# ╠═db696724-8765-11eb-3be2-d775f5fb8a25
# ╠═128d315c-8862-11eb-21f4-6bc6e17c250d
# ╠═9d6df616-8863-11eb-063d-77661d37a5b2
