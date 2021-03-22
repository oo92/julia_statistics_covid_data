### A Pluto.jl notebook ###
# v0.12.21

using Markdown
using InteractiveUtils

# ╔═╡ f93eaf62-89e9-11eb-0ad5-c3f3e0d0ca7b
begin
	using DataFrames, CSV, Plots, StatsPlots, Dates, Parquet, Arrow
	gr()
end

# ╔═╡ c576d69a-89ea-11eb-312f-b7c563540d15
md"### Analysis of COVID-19 pandemic's global impact"

# ╔═╡ f4538cb0-89ea-11eb-2ced-238a408b4ef6
md"###### Onur Özbek"

# ╔═╡ 92fc9f1a-89ea-11eb-1ed6-2b668f66f078
begin
	# COVID-19 Global data
	global_data = download("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_global.csv","covid_19_global_data.csv")
	
	# COVID-19 recovered patients data
	recovered_data = download("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_recovered_global.csv", "covid_19_global_data_recovered.csv" )
	
	# COVID-19 fatality data.
	death_data = download("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_global.csv", "covid_19_global_data_deaths.csv" )
	
	# The below 3 chunks of code converts each dataset to a CSV, then to Parquet and the finally to Arrow.
	df = CSV.read("covid_19_global_data.csv", DataFrame)
	write_parquet("covid_19_global_data.parquet", df)
	df = DataFrame(read_parquet("covid_19_global_data.parquet"))
	Arrow.write("covid_19_global_data.arrow", df)
	df = DataFrame(Arrow.Table("covid_19_global_data.arrow"))
	

	df_recovered = CSV.read("covid_19_global_data_recovered.csv", DataFrame)
	write_parquet("covid_19_global_data_recovered.parquet", df_recovered)
	df_recovered = DataFrame(read_parquet("covid_19_global_data_recovered.parquet"))
	Arrow.write("covid_19_global_data_recovered.arrow", df_recovered)
	df_recovered = DataFrame(Arrow.Table("covid_19_global_data_recovered.arrow"))
	

	df_deaths = CSV.read("covid_19_global_data_deaths.csv", DataFrame)
	write_parquet("covid_19_global_data_deaths.parquet", df_deaths)
	df_deaths = DataFrame(read_parquet("covid_19_global_data_deaths.parquet"))
	Arrow.write("covid_19_global_data_deaths.arrow", df_deaths)
	df_deaths = DataFrame(Arrow.Table("covid_19_global_data_deaths.arrow"))
	
		
end

# ╔═╡ c5def406-89ec-11eb-205c-8745deccc82a
size(df)
# size(df_recovered)
# size(df_deaths)

# ╔═╡ 36b3ffc4-89ee-11eb-3018-195f8f3f5a15
names(df)
# names(df_recovered)
# names(df_deaths)

# ╔═╡ 0e0b8030-89f1-11eb-2a1b-1dce511e73c1
#==
	The data is indexed by countries. The Province/State column gives us information on which jurisdiction in the country the said row belongs to. We don't actually need this and a lot of the provincial data is missing. However, a good way to make use of this is to only get the data for a country where the province/state is missing. This way, the "missing" row gives us information for the entirety of the country. We don't need to further partition our data for each country by it's province/state.
==#

function get_country(dataframe, country::String)
	df_country = dataframe[ismissing.(dataframe[!, Symbol("Province/State")]), :]
	indx = findfirst(df_country[!, Symbol("Country/Region")] .== country)
	return df_country[indx, :]
end

# ╔═╡ 6d4c6c14-8a83-11eb-2ffc-8bfa55609d96
begin
	#=
		Here, we are plotting a time-series plot of the global COVID-19 impact with 		the outliers intact.
	=#
	sample_countries = ["Italy", "Germany", "Brazil", "United Kingdom", "Iran", "Turkey"]
	first_y_axis = DataFrame() # Creating an empty dataframe to plot the 6 countries
	
	#= Getting the column names from the beginning to the end - 4. The reason why is that Arrow reversed the index of the columns and I do not want the last 4 columns as they're redundant data.=#
	dates = names(df)[begin:end-4]
	
	#= Fixing the format of the date. We want the date to be month/day/year and we also want the years to start from 2000 as they were not when this dataset was 		assembled. =#
	date_format = Dates.DateFormat("m/d/y") 
	x_axis = parse.(Date, dates, date_format) .+ Year(2000) 

	#= For the new dataframe, I am populating each column (country) with its corresponding COVID19 data. =#
	for country in sample_countries    
    	data_dfr = get_country(df,country); 
    	data_dfr = DataFrame(data_dfr);           
    	df_rows, df_cols = size(data_dfr);
    	data_dfl = stack(data_dfr, 5:df_cols);       
    	first_y_axis[!,Symbol("$country")] = data_dfl[!,:value]
	end

	#= Although I'm getting both the row and the column from the tuple, I really only need to use the column for plotting =#
	rows, cols = size(first_y_axis)
	
	#= In this while loop, I am going through the dataframe and removing non-numerical data. =#
	i = 1 
	n = rows
	
	while i <= n
    	if prod(isa.(collect((first_y_axis)[i,:]),Number))==0
       		delete!(first_y_axis,i)
       		global x_axis = x_axis[1:end .!= i]
       		global n -= 1
    	end
    	global i += 1
	end
	
	#= This is a good size for the graph to see the plots, the legend and the axis more clearly =#
	gr(size=(2000,670))
	
	#= The @df macro allows me to plot directly from the dataframe, which is very convenient. The parameters of plot are just to lay out the characteristics of what the graph will look like. =#
	@df first_y_axis plot(x_axis, cols(1:cols), 
	    label =  reshape(names(first_y_axis),(1,length(names(first_y_axis)))),
	    xlabel = "Time",
	    ylabel = "Total number of reported cases",
	    xticks = x_axis[1:7:end],
	    xrotation = 45,
	    marker = (:diamond,4),
	    line = (:line, "gray"),
	    legend = :top,
	    grid = false,
	    framestyle = :semi,
	    legendfontsize = 9,
	    tickfontsize = 9,
	    formatter = :plain)
end

# ╔═╡ 7536a56c-8ab6-11eb-3f30-0d0bd6f89542
begin
	#= Here, I am taking a look at the difference between the number of cases reported between the 6 countries each day. The Dataframe reports the total number of cases each day so the daily increase or decrease is really just the difference between the reports of a day and the day before. =#
	
	y_copy = deepcopy(first_y_axis) # Creating a copy of y to avoid changing it           
	#= Getting similar information for the bar plot=#
	dfrows = nrow(y_copy)
	name = names(y_copy)
	
	#= Copying the structure to an empty dataframe with the rows of y_copy - 1 =#
	y_daily = similar(y_copy,dfrows-1)
	
	#= Just like before, I am populating the dataframe with a for loop. This time, I am calculating the data that will be plotted. =#
	for j = 1:length(name)
    	for i = 1:dfrows-1
        	y_daily[!,name[j]][i] = y_copy[!,name[j]][i+1] - y_copy[!,name[j]][i]
    	end
	end
	
	x_daily = deepcopy(x_axis)
	popfirst!(x_daily) #= Removing the 1st entry since daily increase/decrease in COVID-19 contraction reporting can only start from the 1st day onwards. =#

	#= Designing the graph by adding its parameters. =#
	gr(size=(2000,670))
	@df y_daily bar(x_daily, cols(1:cols), 
    	label = reshape(names(first_y_axis),(1,length(names(first_y_axis)))),
    	xlabel = "Time",
    	ylabel = "Daily number of reported cases",
    	xticks = x_axis[1:7:end],
    	xrotation = 45,
    	legend = :top,
    	grid = true,
    	framestyle = :semi,
    	legendfontsize = 9,
    	formatter = :plain)

end

# ╔═╡ bb45d950-8ac6-11eb-3a3d-939fa92db4bc
begin
	#= Taking a look at a different batch of countries =#
	new_countries = ["France", "Russia", "Italy", "Iran", "India", "Germany", "Brazil"]
	
	#= Separating dataframes =#
	y_axis, y_recovered, y_deaths = DataFrame(), DataFrame(), DataFrame()
	
	#= Total confirmed cases =#
	for country in new_countries
		#= Returns the specific row =#
	    dataframe_global = get_country(df,country)
		#= Convert row to a dataframe =#
	    dataframe_global = DataFrame(dataframe_global)
		#= Get the rows and columns =#
	    g_rows, g_cols = size(dataframe_global)
		#= Convert dataframe values to long =#
	    long_data = stack(dataframe_global, 5:g_cols)
		#= Swapping the previous data with its long format =#
	    y_axis[!,Symbol("$country")] = long_data[!,:value]
	
	#= Total recovered cases =#
		#= Returns the specific row =#
	    dataframe_recovered = get_country(df_recovered,country)
		#= Convert row to a dataframe =#
	    dataframe_recovered = DataFrame(dataframe_recovered)
		#= Get the rows and columns =#
	    r_rows, r_cols = size(dataframe_recovered)
		#= Convert dataframe values to long =#
	    r_long_data = stack(dataframe_recovered, 5:r_cols)
		#= Swapping the previous data with its long format =#
	    y_recovered[!,Symbol("$country")] = r_long_data[!,:value]
	
	#= Total deaths =#
	    #= Returns the specific row =#
	    data_dfr_d = get_country(df_deaths,country) 
		#= Convert row to a dataframe =#
	    data_dfr_d = DataFrame(data_dfr_d)
		#= Get the rows and columns =#
	    d_rows, d_cols = size(data_dfr_d)
		#= Convert dataframe values to long =#
	    d_long_data = stack(data_dfr_d, 5:d_cols)
		#= Swapping the previous data with its long format =#
	    y_deaths[!,Symbol("$country")] = d_long_data[!,:value]
	end
end

# ╔═╡ bc283588-8ac7-11eb-38dd-09b9c33715fd
begin
	
	#= A good way to visualize data that is divided into n characteristics is to use a grouped bar. For each country, we can easily see the deaths, the revoeries, confirmed cases and those that are still infected at the time of this data's collection. Since we know the number of confirmed cases, we can calculate the currently infected with this formula:
	
	current_infected = # confirmed cases − (# recovered cases + # deaths) =#
	
	#= convert first dataframe rows into a 1-D array to turn into vectors, since Arrow reversed the index of our columns and the first row is the most recent =#
	confirmed_cases = vec(convert(Array, first(y_axis,1)))
	recovered_cases = vec(convert(Array, first(y_recovered,1)))
	deaths          = vec(convert(Array, first(y_deaths,1)))
	
	#= Creating the 2D array with confirmed, recovered and deaths values =#
	Y = Array{Float64,2}(undef, length(names(y_recovered)), 4)
	Y[:,1] = deaths
	Y[:,2] = confirmed_cases
	Y[:,3] = recovered_cases
	
	#= Calculating the current infections =#
	Y[:,4] = Y[:,2] - (Y[:,3] + Y[:,1])
	
end

# ╔═╡ d56809ac-8ad5-11eb-1562-3fd83fa45d8a
begin
	gr(size=(1000,333))
	@df y_axis groupedbar(names(y_axis), Y, 
	          bar_position = :dodge, 
	          bar_width=0.75,
	          ylabel = "Number of cases",
	          xlabel = "Countries",
	          label=["Deaths" "Confirmed" "Recovered" "Currently infected"],
	          framestyle = :semi,
	          formatter = :plain,
	          legend = :top,
	          grid = true)
end

# ╔═╡ Cell order:
# ╟─c576d69a-89ea-11eb-312f-b7c563540d15
# ╟─f4538cb0-89ea-11eb-2ced-238a408b4ef6
# ╠═f93eaf62-89e9-11eb-0ad5-c3f3e0d0ca7b
# ╠═92fc9f1a-89ea-11eb-1ed6-2b668f66f078
# ╠═c5def406-89ec-11eb-205c-8745deccc82a
# ╠═36b3ffc4-89ee-11eb-3018-195f8f3f5a15
# ╠═0e0b8030-89f1-11eb-2a1b-1dce511e73c1
# ╠═6d4c6c14-8a83-11eb-2ffc-8bfa55609d96
# ╠═7536a56c-8ab6-11eb-3f30-0d0bd6f89542
# ╠═bb45d950-8ac6-11eb-3a3d-939fa92db4bc
# ╠═bc283588-8ac7-11eb-38dd-09b9c33715fd
# ╠═d56809ac-8ad5-11eb-1562-3fd83fa45d8a
