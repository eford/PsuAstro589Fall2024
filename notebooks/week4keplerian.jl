### A Pluto.jl notebook ###
# v0.19.46

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 8be9bf52-a0a3-11ec-045f-3962ad227049
begin
	using CSV, DataFrames, Query
	using Optim
	using Plots, LaTeXStrings, Plots.Measures
	using PlutoUI, PlutoTeachingTools
	using Downloads
	using ParameterHandling

	default(size=(1200,800))
end

# ╔═╡ 82d5eb4f-5724-4c72-b6e0-f6d5fc7f4313
md"""
# Intro to Analyzing RV Timeseries
#### Astro 589: Week 4
"""

# ╔═╡ 57141374-dd5a-4eaa-8235-b2310ef2d600
TableOfContents()

# ╔═╡ c516e3bd-0858-498f-9db8-94395ad72ea0
md"""
# Circular RV Model

Velocity of Planet: 

$$v_{pl} = 2\pi a_{pl} / P$$

$$a = a_{pl} + a_\star$$ 

Velocity of Star:   

$$M_\star v_\star = m_{pl} v_{pl}$$

$$v_\star = \frac{m_{pl}}{M_\star+m_{pl}} \frac{2\pi a}{P}$$

Doppler effective is only sensitive to motion projected onto observer's line of sight

$$RV_{\star} = \frac{m_{pl}}{M_\star+m_{pl}} \frac{2\pi a}{P} \sin i$$

"""

# ╔═╡ 6be0b0bf-24e3-417c-a257-c4f61a31e1e3
md"""
# Keplerian Orbit

$(Resource("https://upload.wikimedia.org/wikipedia/commons/thumb/e/eb/Orbit1.svg/1137px-Orbit1.svg.png"))
Credit: [Lasunncty](https://en.wikipedia.org/wiki/User:Lasunncty) via [Wikipedia](https://commons.wikimedia.org/wiki/File:Orbit1.svg) ([CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/deed.en) license)
"""

# ╔═╡ 4eace0ad-5222-4e1d-9760-7e139478e866
md"""
## Keplerian RV Model

$$\Delta RV(t) = \frac{K}{\sqrt{1-e^2}} \left[\cos(\omega+ν(t)) + e \cos(\omega) \right]$$

```math
\begin{eqnarray}
K & = & \frac{2\pi a \sin i}{P} \frac{m_{pl}}{M_\star+m_{pl}} \\
%  & = & \frac{2\pi a \sin i}{P} \\
\end{eqnarray}
```

$$\tan\left(\frac{\nu(t)}{2}\right) = \sqrt{\frac{1+e}{1-e}} \tan\left(\frac{E(t)}{2}\right)$$

- Mean anomaly ($M(t)$) increases linear with time
- Eccentric anomaly ($E(t)$) specifies position in orbit using angle from center of elipse 
- True anomaly ($\nu(t)$ or $f(t)$ or $T(t)$) specifies position in orbit using angle from focus of ellipse
"""

# ╔═╡ 8bc702c6-b3b2-4a81-901c-ce361b8c10e5
md"""
$(Resource("https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Eccentric_and_True_Anomaly.svg/1229px-Eccentric_and_True_Anomaly.svg.png"))
Credit: [CheCheDaWaff](https://commons.wikimedia.org/wiki/User:CheCheDaWaff) via [Wikipedia](https://commons.wikimedia.org/wiki/File:Eccentric_and_True_Anomaly.svg) ([CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.en) license)
"""

# ╔═╡ 637a5d00-0e91-4227-aac5-829094935d91
md"""
### Keplerian Orbit in Time

$$M(t) = \frac{2π t}{P} + M_0$$


#### Kepler Equation
$$M(t) = E(t) - e \sin(E(t))$$
"""

# ╔═╡ 4bdcca25-c37f-4079-b222-be773adc2b8f
md"### Interactive Keplerian RV Model"

# ╔═╡ 2306a2d5-2924-45e0-adec-b90d536d2949
md"""
P: $(@bind P_plt NumberField(1:0.1:100, default=4))
K: $(@bind K_plt NumberField(0:0.1:10, default=3))
e: $(@bind e_plt NumberField(0:0.05:1, default=0))
ω: $(@bind ω_plt NumberField(0:0.05:2π, default=0))
M₀: $(@bind M0_plt NumberField(0:0.05:2π, default=0))
"""

# ╔═╡ 3d1821a6-f134-49d6-a4b0-39d6d28ab420
md"""
# Example RV Data
"""

# ╔═╡ 873c94d4-29f1-4664-87b1-d70615c0f8ed
# Examples to show: 114783, 119850, 13931, 187123

# ╔═╡ 21834080-14de-4926-9766-5a3ad994e2a1
md"""
# Fitting RV Model to data
"""

# ╔═╡ d2d1cf44-255a-47bf-ba3d-42169c6af060
md"""
## Fit one planet
"""

# ╔═╡ 49fdca20-46fd-4f31-94f1-ed58f3b32305
md"""
Fit 1-planet model: $(@bind try_fit_1pl CheckBox())
"""

# ╔═╡ a318c478-f71c-457b-9c54-fe69e964849a
θinit1 = [496.9, 10, 0.1, 0.1, 0.1, 1, 2, 1e-4, 2.0] # for 114783

# ╔═╡ 55034abb-34e3-4fab-9b80-c82019a67756
md"""
## Fit 2nd planet to residuals
"""

# ╔═╡ fac9b01f-3a92-49da-9ec9-2e6502d595d9
md"""
Fit 2nd planet to residuals: $(@bind try_fit_2nd_pl_to_resid CheckBox())
"""

# ╔═╡ 26c601fb-d62f-47f2-a7ff-e7ca63ad9dcd
θinit_resid = [4319.0, 5.0, 0.1, 0.1, π/4, 1.0, -1.0 , 0.0001, 1.0];  # for 114783

# ╔═╡ de533ac4-6870-40f8-8bad-f8c62694e719
md"""
## Fit 2-planet model
"""

# ╔═╡ bc0d6fd6-de10-4c58-b55c-7bca8fbc123a
md"""
Fit 2nd planet model: $(@bind try_fit_2pl CheckBox())
"""

# ╔═╡ b60aadbc-4e70-414e-9fdc-c3b042cb17bf
md"# Setup"

# ╔═╡ 8c1ed181-6386-4c55-ba87-18354b6f02b5
ChooseDisplayMode()

# ╔═╡ c3a9ed24-93a0-4cec-8233-3a93be5408f3
notebook_id = PlutoRunner.notebook_id[] |> string;

# ╔═╡ 69f40924-6b24-4014-8c1b-f600a0759aab
md"## Keplerian Radial Velocity Model Code"

# ╔═╡ a7514405-af4c-4f16-8508-91ee624d8a1c
function calc_true_anom(ecc_anom::Real, e::Real)
	true_anom = 2*atan(sqrt((1+e)/(1-e))*tan(ecc_anom/2))
end

# ╔═╡ 4f047081-a4d6-414b-9c3e-0eb055c730b3
"""
   ecc_anom_init_guess_danby(mean_anomaly, eccentricity)

Returns initial guess for the eccentric anomaly for use by itterative solvers of Kepler's equation for bound orbits.  

Based on "The Solution of Kepler's Equations - Part Three"
Danby, J. M. A. (1987) Journal: Celestial Mechanics, Volume 40, Issue 3-4, pp. 303-312 (1987CeMec..40..303D)
"""
function ecc_anom_init_guess_danby(M::Real, ecc::Real)
	@assert -2π<= M <= 2π
	@assert 0 <= ecc <= 1.0
    if  M < zero(M)
		M += 2π
	end
    E = (M<π) ? M + 0.85*ecc : M - 0.85*ecc
end;

# ╔═╡ 8f700e72-df0f-4e68-85fe-7fbe8da7fbb1
"""
   update_ecc_anom_laguerre(eccentric_anomaly_guess, mean_anomaly, eccentricity)

Update the current guess for solution to Kepler's equation
  
Based on "An Improved Algorithm due to Laguerre for the Solution of Kepler's Equation"
   Conway, B. A.  (1986) Celestial Mechanics, Volume 39, Issue 2, pp.199-211 (1986CeMec..39..199C)
"""
function update_ecc_anom_laguerre(E::Real, M::Real, ecc::Real)
  #es = ecc*sin(E)
  #ec = ecc*cos(E)
  (es, ec) = ecc .* sincos(E)  # Does combining them provide any speed benefit?
  F = (E-es)-M
  Fp = one(M)-ec
  Fpp = es
  n = 5
  root = sqrt(abs((n-1)*((n-1)*Fp*Fp-n*F*Fpp)))
  denom = Fp>zero(E) ? Fp+root : Fp-root
  return E-n*F/denom
end;

# ╔═╡ 690205fb-0b95-4614-9b66-dec362ed693c
begin
	calc_ecc_anom_cell_id = PlutoRunner.currently_running_cell_id[] |> string
	calc_ecc_anom_url = "#$(calc_ecc_anom_cell_id)"
	"""
	   calc_ecc_anom( mean_anomaly, eccentricity )
	   calc_ecc_anom( param::Vector )
	
	Estimates eccentric anomaly for given 'mean_anomaly' and 'eccentricity'.
	If passed a parameter vector, param[1] = mean_anomaly and param[2] = eccentricity. 
	
	Optional parameter `tol` specifies tolerance (default 1e-8)
	"""
	function calc_ecc_anom end
	
	function calc_ecc_anom(mean_anom::Real, ecc::Real; tol::Real = 1.0e-8)
	  	if !(0 <= ecc <= 1.0)
			println("mean_anom = ",mean_anom,"  ecc = ",ecc)
		end
		@assert 0 <= ecc <= 1.0
		@assert 1e-16 <= tol < 1
	  	M = rem2pi(mean_anom,RoundNearest)
	    E = ecc_anom_init_guess_danby(M,ecc)
		local E_old
	    max_its_laguerre = 200
	    for i in 1:max_its_laguerre
	       E_old = E
	       E = update_ecc_anom_laguerre(E_old, M, ecc)
	       if abs(E-E_old) < tol break end
	    end
	    return E
	end
	
	function calc_ecc_anom(param::Vector; tol::Real = 1.0e-8)
		@assert length(param) == 2
		calc_ecc_anom(param[1], param[2], tol=tol)
	end;
end

# ╔═╡ 4d4d3ea6-3d87-4ec3-9625-7ba00e17dbcf
Markdown.parse("""
No closed form solution for \$E\$, so solve for \$E(t)\$ iteratively 
(see [code for `calc_ecc_anom(M, e)`]($(calc_ecc_anom_url))
""")

# ╔═╡ 3fbcc50d-9f6a-4aec-9a8f-f2f525223f0e
begin 
	""" Calculate RV from t, P, K, e, ω and M0	"""
	function calc_rv_keplerian end 
	#calc_rv(t, p::Vector) = calc_rv(t, p[1],p[2],p[3],p[4],p[5])
	calc_rv_keplerian(t, p::Vector) = calc_rv_keplerian(t, p...)
	function calc_rv_keplerian(t, P,K,e,ω,M0) 
		mean_anom = t*2π/P-M0
		ecc_anom = calc_ecc_anom(mean_anom,e)
		true_anom = calc_true_anom(ecc_anom,e)
		rv = K/sqrt((1-e)*(1+e))*(cos(ω+true_anom)+e*cos(ω))
	end
end

# ╔═╡ bab9033c-b9ee-45c1-9466-838e40bdb920
function make_rv_vs_phase_panel(e, ω; P::Real=1, K::Real=1, M0::Real =0, panel_label="", t_max::Real = P, xticks=false, yticks=false )
	plt = plot(legend=:none, widen=false, xticks=xticks, yticks=yticks, margin=0mm, link=:none)
	t_plt = collect(range(0,stop=t_max,length=1000))
	rv_plt = calc_rv_keplerian.(t_plt, P, K, e, ω, M0)
	plot!(plt,t_plt,rv_plt, linecolor=:black) #, lineweight=4)
	xlims!(0,P)
	ylims!(-3.0,3.0)
	if length(panel_label)>0
		annotate!(plt, 0.505,2.1, text(panel_label,24,:center))
	end
	return plt
end

# ╔═╡ 8d0a2a57-1bbe-4145-9e1b-de125c7635ef
let
	ω_list = [0,π/4,π/2, 3π/4, π]
	ωstr_list = [L"0",L"\frac{\pi}{4}",L"\frac{\pi}{2}", L"\frac{3\pi}{4}", L"\pi"]
	e_list = [0.2, 0.4, 0.6, 0.8]
	plts = [ make_rv_vs_phase_panel(e,ω_list[ωi], panel_label = L"e=" * latexstring(e) * L"\;\; \omega=" * ωstr_list[ωi] ) for ωi in 1:length(ω_list),  e in e_list ]
	#annotate!(plts[3,4],0.5,-4,text(L"\mathrm{Time}",48))
	#annotate!(plts[1,3],-0.25,4,text(L"\mathrm{RV}",48,rotation=90))
	l = @layout [  b{0.04w} [ grid(4,5); c{0.03h} ]  ]
	plt_top = [ plot(link=:none,xlabel="", ylabel="",xticks=false,yticks=false,frame=:none) for e in e_list ]
	
	#annotate!(plt_top[1],0.5,0.5,text(L"\omega=0",36))
	plt_left = plot(link=:none,xlabel="", ylabel="",xticks=false,yticks=false,frame=:none)
	annotate!(plt_left,0.5,0.525,text(L"\mathrm{RV}",36,rotation=90,:center))
	plt_bottom = plot(link=:none,xlabel="", ylabel="",xticks=false,yticks=false,frame=:none)
	annotate!(plt_bottom,0.5,0.5,text(L"\mathrm{Time}",36,:center))
	plt = plot(plt_left,plts...,plt_bottom,  link=:none, layout = l, size=(2400,2400), thinkness_scaling=8)
end

# ╔═╡ ee7aaab9-5e4f-46ab-8100-75be142fba72
begin 
	plt_1pl = make_rv_vs_phase_panel(e_plt, ω_plt, P=P_plt, K=K_plt, M0=M0_plt, t_max = 100, xticks=true, yticks=true)
	xlabel!(plt_1pl, L"\mathrm{Time} \;\;\; (day)")
	ylabel!(plt_1pl, L"\Delta RV\;\;\;\; (m/s)")
	xlims!(plt_1pl,0,100)
	ylims!(plt_1pl,-6,6)
end

# ╔═╡ 7047d464-efdd-4315-b930-5b2e8a3d93c5
md"""
### Fitting Keplerian RV model
"""

# ╔═╡ cc7006c7-e3ef-470a-b93e-5743a27a32d9
begin 
	""" Calculate RV from t, P, K, e, ω, M0	and C"""
	function calc_rv_keplerian_plus_const end 
	calc_rv_keplerian_plus_const(t, p::Vector) = calc_rv_keplerian_plus_const(t, p...)
	
	function calc_rv_keplerian_plus_const(t, P,K,e,ω,M0,C) 
		calc_rv_keplerian(t, P,K,e,ω,M0) + C
	end
end

# ╔═╡ 5677766e-6466-4b0b-b703-61f9aaaf5cd3
begin
	""" Calculate RV from t, P1, K1, e1, ω1, M01, P2, K2, e2, ω2, M02 and C"""
	calc_rv_2keplerians_plus_const(t, p::Vector) = calc_rv_2keplerians_plus_const(t, p...)
	function calc_rv_2keplerians_plus_const(t, P1,K1,e1,ω1,M01,P2,K2,e2,ω2,M02,C) 
		calc_rv_keplerian(t, P1,K1,e1,ω1,M01) + calc_rv_keplerian(t, P2,K2,e2,ω2,M02) + C
	end
end

# ╔═╡ 56d09fea-e2c2-4345-a089-419ac863ac43
""" Calculate RV from t, P, K, e, ω, M0	and C with optional slope and t_mean"""
function model_1pl(t, P, K, e, ω, M, C; slope=0.0, t_mean = 0.0)
	calc_rv_keplerian(t-t_mean,P,K,e,ω,M) + C + slope * (t-t_mean)
end

# ╔═╡ 19a96558-4c9f-4bad-8fc2-735c813bd756
""" Calculate RV from t, P1, K1, e1, ω1, M01, P2, K2, e2, ω2, M02 and C with optional slope and t_mean"""
function model_2pl(t, P1, K1, e1, ω1, M1, P2, K2, e2, ω2, M2, C; slope=0.0, t_mean = 0.0)
	rv = calc_rv_keplerian(t-t_mean,P1,K1,e1,ω1,M1) + 
		 calc_rv_keplerian(t-t_mean,P2,K2,e2,ω2,M2) + 
		 C + slope * (t-t_mean)
end

# ╔═╡ 3932fb9d-2897-4d64-8dba-a51799d1aa7a
""" Convert vector of (P,K,h,k,ω+M0) to vector of (P, K, e, ω, M0) """
function PKhkωpM_to_PKeωM(x::Vector) 
	(P, K, h, k, ωpM) = x
	ω = atan(h,k)
	return [P, K, sqrt(h^2+k^2), ω, ωpM-ω]
end

# ╔═╡ d4e5cd92-21c0-4073-ab3e-8cd5804976c8
md"""
### Loss functions
The functions below:
- assume observations from exactly two instruments.
- make use of the global variables `data1`, `data2` and `t_mean`.
"""

# ╔═╡ d5febe7d-bf9b-4793-96f3-9c31b641b3ae
md"""
### Ingest data
"""

# ╔═╡ 2e51744b-b040-4f21-94b8-ffe9cd1e149e
begin
	fn = joinpath("../_assets/week4/legacy_data.csv")
	if !isfile(fn) || !(filesize(fn)>0)
		path = joinpath(pwd(),"data")
		mkpath(path)
		fn = joinpath(path,"legacy_data.csv")
		fn = Downloads.download("https://github.com/leerosenthalj/CLSI/raw/master/legacy_tables/legacy_data.csv", fn)
	end
	if filesize(fn) > 0
		df_all = CSV.read(fn, DataFrame)
		select!(df_all,["name","jd","mnvel","errvel", "cts","sval","tel"])
		# Rename columns to match labels from table in original paper
		rename!(df_all, "name"=>"Name","jd"=>"d","mnvel"=>"RVel","errvel"=>"e_RVel","tel"=>"Inst", "sval"=>"SVal")	
		star_names = unique(df_all.Name)
		md"Read RVs for $(length(star_names)) stars from California Legacy Survey from https://github.com/leerosenthalj/CLSI & from [Rosenthal et al. (2021)](https://doi.org/10.3847/1538-4365/abe23c) into `df_all`."
	else
		df_all = DataFrame()
		star_names = String[""]

		danger(md"Error reading data file with RVs.  Expect empty plots below.")
	end
	
end

# ╔═╡ 5a73b1fc-99bc-4530-ae4a-49ce25df99dc
md"""
Star ID to plot: HD $(@bind star_name_to_plt Select(star_names; default="114783"))
"""

# ╔═╡ 253decc1-35c7-4454-b500-4f28e1087d36
starid = searchsortedfirst(star_names,star_name_to_plt);

# ╔═╡ 5e92054a-ca9e-4949-9727-5a9ed14003c0
begin
	star_name = star_names[starid]
	df_star = df_all |> @filter( _.Name == star_name ) |> DataFrame
end;

# ╔═╡ bce3f35c-07a1-48ef-8a29-243b2215fcb5
begin 
	df_star_by_inst = DataFrame()
	try
	df_star_by_inst = df_star |> @groupby( _.Inst ) |> @map( {bjd = _.d, rv = _.RVel, σrv = _.e_RVel, inst= key(_), nobs_inst=length(_) }) |> DataFrame;
	catch
	end
end;

# ╔═╡ 8b1f8b91-12b5-4e61-a8ff-63538189cf34
t_offset = 2450000;  # So labels on x-axis are more digestable

# ╔═╡ 5edc2a2d-6f63-4ac6-8c33-2c5d670bc466
let
	#upscale
	plt = plot() #legend=:none, widen=true)
	num_inst = size(df_star_by_inst,1)
	rvoffset = zeros(4) # [result2.minimizer[11], result2.minimizer[12], 0, 0]
	#rvoffset[1:2] .= result1.minimizer[6:7]
	#slope = result1.minimizer[8]
	#rvoffset[1:2] .= result2.minimizer[11:12]
	for inst in 1:num_inst
		lab = df_star_by_inst[inst,:inst]
		if lab == "lick" continue end
		if lab == "k" lab = "Keck (pre)" end
		if lab == "j" lab = "Keck (post)" end
		if lab == "apf" lab = "APF" end
		scatter!(df_star_by_inst[inst,:bjd].-t_offset,
				df_star_by_inst[inst,:rv].-rvoffset[inst],
				yerr=collect(df_star_by_inst[inst,:σrv]),
				label=lab)
				#markersize=4*upscale, legendfontsize=upscale*12
		#plot!(t_plt,model_1pl)
		#plot!(t_plt.-2450000,model_2pl)
		#scatter!(df_star_by_inst[2,:bjd].-2450000,df_star_by_inst[2,:rv], yerr=collect(df_star_by_inst[2,:σrv]),label=:none)
		#scatter!(df_star_by_inst[3,:bjd].-2450000,df_star_by_inst[3,:rv], yerr=collect(df_star_by_inst[3,:σrv]),label=:none)
		#scatter!(df_star_by_inst[4,:bjd].-2450000,df_star_by_inst[4,:rv], yerr=collect(df_star_by_inst[4,:σrv]),label=:none)
	end
	xlabel!("Time (d)")
	ylabel!("RV (m/s)")
	title!("HD " * star_name )
	#savefig(plt,joinpath(homedir(),"Downloads","RvEx.pdf"))
	plt
end

# ╔═╡ fcf19e04-3e35-4a01-8036-fd5b283fdd37
if size(df_star_by_inst,1)>0  # Warning: Assume exactly 2 instruments providing RV data
	data1 = (t=collect(df_star_by_inst[1,:bjd]).-t_offset, rv=collect(df_star_by_inst[1,:rv]), σrv=collect(df_star_by_inst[1,:σrv]))
	if size(df_star_by_inst,1) > 1
		data2 = (t=collect(df_star_by_inst[2,:bjd]).-t_offset, rv=collect(df_star_by_inst[2,:rv]), σrv=collect(df_star_by_inst[2,:σrv]))
	else
		data2 = (t=Float64[], rv=Float64[], σrv=Float64[])
	end
	t_mean = (sum(data1.t)+sum(data2.t))/(length(data1.t).+length(data2.t))
	t_plt = range(minimum(vcat(data1.t,data2.t)), stop=maximum(vcat(data1.t,data2.t)), step=1.0)
end;

# ╔═╡ 9da83c61-cbcb-4c13-83d1-21a26b1c59d1
function loss_1pl(θ) 
	(P1, K1, h1, k1, Mpω1, C1, C2, slope, σj ) = θ
	( P1, K1, e1, ω1, M1 ) = PKhkωpM_to_PKeωM([P1, K1, h1, k1, Mpω1])
	if e1>1 return 1e6*e1 end
	rv_model1 = model_1pl.(data1.t,P1,K1,e1,ω1,M1,C1, slope=slope, t_mean=t_mean)
	loss = 0.5*sum(((rv_model1.-data1.rv)./(data1.σrv.+σj^2)).^2)
	rv_model2 = model_1pl.(data2.t,P1,K1,e1,ω1,M1,C2, slope=slope, t_mean=t_mean)
	loss += 0.5*sum((rv_model2.-data2.rv).^2 ./(data2.σrv.^2 .+σj^2))
	loss += 0.5*sum(log.(2π*(data1.σrv.^2 .+σj^2)))
	loss += 0.5*sum(log.(2π*(data2.σrv.^2 .+σj^2)))
	return loss
end

# ╔═╡ 41b2eea0-3049-4fa5-803e-83a54b74ef27
if try_fit_1pl && @isdefined data1 
	result1 = Optim.optimize(loss_1pl, θinit1, BFGS(), autodiff=:forward);
end

# ╔═╡ 84c68b29-6707-4761-bde1-2dcabe5a0ac9
if @isdefined result1 
	result1.minimizer[1:5]
end

# ╔═╡ fa3fe244-75cf-434b-8de1-5fca5db06c8b
if try_fit_1pl && @isdefined data1
	pred_1pl = map(t->model_1pl(t,PKhkωpM_to_PKeωM(result1.minimizer[1:5])...,0.0,slope=0.0, t_mean=t_mean),t_plt);
end

# ╔═╡ 278d1fbd-7c64-4544-b37a-8258f493b3db
if @isdefined result1
	resid1 = vcat(
	 data1.rv .- model_1pl.(data1.t,PKhkωpM_to_PKeωM(result1.minimizer[1:5])...,result1.minimizer[6],slope=result1.minimizer[8], t_mean=t_mean),
	data2.rv .- model_1pl.(data2.t,PKhkωpM_to_PKeωM(result1.minimizer[1:5])...,result1.minimizer[7],slope=result1.minimizer[8], t_mean=t_mean) )
end;

# ╔═╡ ba141b21-ab58-400a-a41a-9cdd4dd5987d
function loss_1pl_resid(θ) 
	(P1, K1, h1, k1, Mpω1, C1, C2, slope, σj  ) = θ
	( P1, K1, e1, ω1, M1 ) = PKhkωpM_to_PKeωM([P1, K1, h1, k1, Mpω1])
	if e1>1 return 1e6*e1 end
	rv_model1 = model_1pl.(data1.t,P1,K1,e1,ω1,M1,C1, slope=slope, t_mean=t_mean)
	loss = 0.5*sum(((rv_model1.-resid1[1:length(data1.t)])./(data1.σrv.+σj^2)).^2)
	rv_model2 = model_1pl.(data2.t,P1,K1,e1,ω1,M1,C2, slope=slope, t_mean=t_mean)
	loss += 0.5*sum(((rv_model2.-resid1[length(data1.t)+1:end])./(data2.σrv.+σj^2)).^2)
	loss += 0.5*sum(log.(2π*(data1.σrv.^2 .+σj^2)))
	loss += 0.5*sum(log.(2π*(data2.σrv.^2 .+σj^2)))
	return loss
end

# ╔═╡ a847e31d-9007-478b-b1e3-ffb8e55a6f3c
if try_fit_2nd_pl_to_resid && (@isdefined data1) && (@isdefined resid1)
result_resid = Optim.optimize(loss_1pl_resid, θinit_resid, BFGS(),autodiff=:forward ) ;
end

# ╔═╡ abc38d23-8665-4377-9a25-9e9c5a10a7bf
if @isdefined result_resid
	model_resid = map(t->calc_rv_keplerian(t.-t_mean,PKhkωpM_to_PKeωM(result_resid.minimizer[1:5])...),t_plt);
end;

# ╔═╡ 844ede38-9596-47a6-b30b-9eff622a2330
if @isdefined result_resid
let
	#upscale
	plt = plot(legend=:none, widen=true)
	num_inst = size(df_star_by_inst,1)
	rvoffset = result1.minimizer[6:7]
	slope = result1.minimizer[8]

	scatter!(data1.t,
				data1.rv.-
				model_1pl.(data1.t,PKhkωpM_to_PKeωM(result1.minimizer[1:5])...,rvoffset[1],slope=result1.minimizer[8], t_mean=t_mean),
				yerr=data1.σrv) #,
				#markersize=4*upscale, legendfontsize=upscale*12)
	scatter!(data2.t,
				data2.rv.-
				model_1pl.(data2.t,PKhkωpM_to_PKeωM(result1.minimizer[1:5])...,rvoffset[2],slope=result1.minimizer[8], t_mean=t_mean),
				yerr=data2.σrv),
				#markersize=4*upscale, legendfontsize=upscale*12)
	plot!(t_plt, model_resid)
	xlabel!("Time (d)")
	ylabel!("RV (m/s)")
	title!("HD " * star_name * " (residuals to 1 planet model)")
	#savefig(plt,joinpath(homedir(),"Downloads","RvEx.pdf"))
	plt
end
end

# ╔═╡ 393c7568-a234-4ef5-97a6-4af630e355e5
function loss_2pl(θ) 
	(P1, K1, h1, k1, Mpω1, P2, K2, h2, k2, Mpω2, C1, C2, slope, σj ) = θ
	(P1, K1, e1, ω1, M1 ) = PKhkωpM_to_PKeωM([P1, K1, h1, k1, Mpω1])
	(P2, K2, e2, ω2, M2 ) = PKhkωpM_to_PKeωM([P2, K2, h2, k2, Mpω2])
	if e1>1 return 1e6*e1 end
	if e2>1 return 1e6*e2 end
	rv_model1 = model_2pl.(data1.t,P1,K1,e1,ω1,M1,P2,K2,e2,ω2,M2,C1, slope=slope, t_mean=t_mean)
	loss = 0.5*sum((rv_model1.-data1.rv).^2 ./(data1.σrv.^2 .+σj^2))
	loss += 0.5*sum(log.(2π*(data1.σrv.^2 .+σj^2)))
	rv_model2 = model_2pl.(data2.t,P1,K1,e1,ω1,M1,P2,K2,e2,ω2,M2,C2, slope=slope, t_mean=t_mean)
	loss += 0.5*sum((rv_model2.-data2.rv).^2 ./(data2.σrv.^2 .+σj^2))
	loss += 0.5*sum(log.(2π*(data2.σrv.^2 .+σj^2)))
	return loss
end

# ╔═╡ dbc0e11e-d3e0-46a4-92c5-3afc31463c03
if try_fit_2pl && (@isdefined result1) && (@isdefined result_resid)
	θinit2 = [result1.minimizer[1:5]..., result_resid.minimizer[1:5]..., result1.minimizer[6]+result_resid.minimizer[6],result1.minimizer[7]+result_resid.minimizer[7], result1.minimizer[8]+result_resid.minimizer[8], result_resid.minimizer[9]];
	result2 = Optim.optimize(loss_2pl, θinit2, BFGS(), autodiff=:forward)
end

# ╔═╡ f0febfcd-f0f9-4ce8-a3ab-673ad2f19e5a
if (@isdefined result1) && (@isdefined result2)
	pred_2pl = map(t->model_2pl(t,PKhkωpM_to_PKeωM(result2.minimizer[1:5])...,PKhkωpM_to_PKeωM(result2.minimizer[6:10])...,0.0,slope=result2.minimizer[13], t_mean=t_mean),t_plt)
	resid2 = vcat(
	 data1.rv .- model_2pl.(data1.t,PKhkωpM_to_PKeωM(result2.minimizer[1:5])...,PKhkωpM_to_PKeωM(result2.minimizer[6:10])...,result2.minimizer[11],slope=result2.minimizer[13], t_mean=t_mean),
	data2.rv .- model_2pl.(data2.t,PKhkωpM_to_PKeωM(result2.minimizer[1:5])...,PKhkωpM_to_PKeωM(result2.minimizer[6:10])...,result2.minimizer[12],slope=result2.minimizer[13], t_mean=t_mean) )
end;

# ╔═╡ 849d5f32-f7c4-45cf-bc9d-85eae6c13d4f
if @isdefined resid2
	plt_resid = plot(legend=:none)
	
	scatter!(data1.t, resid2[1:length(data1.t)], yerr=data1.σrv)
	scatter!(data2.t, resid2[length(data1.t)+1:end], yerr=data2.σrv)
	plot!(t_plt,t_plt.*0, linestyle=:dot, linecolor=:black)
	xlabel!("Time (d)")
	ylabel!("ΔRV (m/s)")
end;

# ╔═╡ 43ae8d15-6381-4c86-b08d-2d12cd4bc653
if @isdefined result1
let
	#upscale
	plt = plot() #legend=:none, widen=true)
	num_inst = size(df_star_by_inst,1)
	rvoffset = zeros(4) # [result2.minimizer[11], result2.minimizer[12], 0, 0]
	rvoffset[1:2] .= result1.minimizer[6:7]
	slope = result1.minimizer[8]
	#rvoffset[1:2] .= result2.minimizer[11:12]
	for inst in 1:num_inst
		lab = df_star_by_inst[inst,:inst]
		if lab == "lick" continue end
		if lab == "k" lab = "Keck (pre)" end
		if lab == "j" lab = "Keck (post)" end
		if lab == "apf" lab = "APF" end
		scatter!(df_star_by_inst[inst,:bjd].-t_offset,
				df_star_by_inst[inst,:rv].-rvoffset[inst],
				yerr=collect(df_star_by_inst[inst,:σrv]),
				label=lab)
		#plot!(t_plt,model_1pl)
		#plot!(t_plt.-2450000,model_2pl)
		#scatter!(df_star_by_inst[2,:bjd].-2450000,df_star_by_inst[2,:rv], yerr=collect(df_star_by_inst[2,:σrv]),label=:none)
		#scatter!(df_star_by_inst[3,:bjd].-2450000,df_star_by_inst[3,:rv], yerr=collect(df_star_by_inst[3,:σrv]),label=:none)
		#scatter!(df_star_by_inst[4,:bjd].-2450000,df_star_by_inst[4,:rv], yerr=collect(df_star_by_inst[4,:σrv]),label=:none)
	end
	plot!(t_plt,pred_1pl, label=:none)
	xlabel!("Time (d)")
	ylabel!("RV (m/s)")
	title!("HD " * star_name )
	#savefig(plt,joinpath(homedir(),"Downloads","RvEx.pdf"))
	plt
end
end

# ╔═╡ 1b260d22-e035-4991-bd42-4abd6f6b0333
if @isdefined result2
	#upscale
	plt_fit = plot(widen=true, xticks=false)
	num_inst = size(df_star_by_inst,1)
	rvoffset = result2.minimizer[11:12]
	slope = result2.minimizer[13]
	#rvoffset[1:2] .= result2.minimizer[11:12]
	for inst in 1:num_inst
		lab = df_star_by_inst[inst,:inst]
		if lab == "lick" continue end
		if lab == "k" lab = "Keck (pre)" end
		if lab == "j" lab = "Keck (post)" end
		if lab == "apf" lab = "APF" end
		scatter!(df_star_by_inst[inst,:bjd].-t_offset,
				df_star_by_inst[inst,:rv].-rvoffset[inst],
				yerr=collect(df_star_by_inst[inst,:σrv]),
				label=lab)
				#markersize=3*upscale, legendfontsize=upscale*12,
		#plot!(t_plt,model_1pl)
		#plot!(t_plt.-2450000,model_2pl)
		#scatter!(df_star_by_inst[2,:bjd].-2450000,df_star_by_inst[2,:rv], yerr=collect(df_star_by_inst[2,:σrv]),label=:none)
		#scatter!(df_star_by_inst[3,:bjd].-2450000,df_star_by_inst[3,:rv], yerr=collect(df_star_by_inst[3,:σrv]),label=:none)
		#scatter!(df_star_by_inst[4,:bjd].-2450000,df_star_by_inst[4,:rv], yerr=collect(df_star_by_inst[4,:σrv]),label=:none)
	end
	plot!(t_plt,pred_2pl,linecolor=:black, label=:none)
	xlabel!("Time (d)")
	ylabel!("RV (m/s)")
	#title!("HD " * star_name )
	#savefig(plt_fit,joinpath(homedir(),"Downloads","RvEx.pdf"))
	plt_fit
end;

# ╔═╡ 449a4faf-0ba8-4325-a902-427951c60036
if @isdefined plt_fit 
	l = @layout [a{0.7h} ; b ]
	plt_combo = 
	plot(plt_fit, plt_resid, layout = l)
	plt_combo
end

# ╔═╡ 93d115f3-ab51-4425-8bc8-33dc9b37bd87
md"""
## Code for parsing machine readable tables from AAS Journals
(Not actually used here, since found CSV version of files at https://github.com/leerosenthalj/CLSI.  But potentially useful for student projects.)
"""

# ╔═╡ ad74edd0-5056-48f6-9f5c-19a46c0b7277
#=begin
	fn = joinpath("../_assets/week4/","apjsabe23ct6_mrt.txt");
	#=
	if !isfile(fn) || !(filesize(fn)>0)
		fn = Downloads.download("https://psuastro497.github.io/Fall2022/assets/week4/apjsabe23ct6_mrt.txt", fn)
	end
	=#
	if filesize(fn)>0
		df_all = read_apj_mrt(fn)
		star_names = unique(df_all.Name)
		md"Read machine readable version of Table 6 from [Rosenthal et al. (2021)](https://doi.org/10.3847/1538-4365/abe23c) into `df_all`."
	else 
		df_all = DataFrame()
		star_names = String[""]
		danger(md"Error reading data file with RVs.  Expect empty plots below.")
	end
end
=#

# ╔═╡ bc7e067b-a170-40e0-b9f1-11b097e72a09
function extract_entry(line::AbstractString, fmt_info)
	substr = line[parse(Int,fmt_info[1]):parse(Int,fmt_info[2])]
	if occursin("--",substr)
		return missing
	end
	if  fmt_info[3] == "A" 
		return strip(substr)
	end
	if !occursin(r"\d",substr) 
		return missing
	end
	if fmt_info[3] == "I" 
		return parse(Int,substr)
	elseif  fmt_info[3] == "F" 
		return parse(Float64,substr)
	else
		@warn "Need to add instructions for parsing type " fmt_info[1][3]
		return nothing
	end
end

# ╔═╡ d5036d21-76b3-41f9-8c34-59c8afe9ffe2
function read_apj_mrt(fn::AbstractString)
	lines = readlines(fn)
	line_start_fmt_specs = findfirst(l->occursin("Bytes",l),lines)+2
	line_stop_fmt_specs = findfirst(l->occursin(r"^\-+$",l),lines[line_start_fmt_specs:end]) + (line_start_fmt_specs-1) -1
	line_data_start = findlast(l->occursin(r"^\-+$",l),lines) +1
	fmt_info = map(l->match(r"^\s*(\d+)-\s+(\d+)\s+(\w)(\d\.?\d*)\s*(\S+)\s+(\S+)\s+(.*)$",l).captures,lines[line_start_fmt_specs:line_stop_fmt_specs]) 
	colnames = map(f->f[6],fmt_info)
	data = map(fmt->Base.Fix2(extract_entry,fmt).(lines[line_data_start:length(lines)]),fmt_info)
	df = DataFrame(data,colnames )
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CSV = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Downloads = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
Optim = "429524aa-4258-5aef-a3af-852621145aeb"
ParameterHandling = "2412ca09-6db7-441c-8e3a-88d5709968c5"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoTeachingTools = "661c6b06-c737-4d37-b85c-46df65de6f69"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Query = "1a8c2f83-1ff3-5112-b086-8aa67b057ba1"

[compat]
CSV = "~0.10.3"
DataFrames = "~1.3.2"
LaTeXStrings = "~1.3.0"
Optim = "~1.7.2"
ParameterHandling = "~0.4.5"
Plots = "~1.26.0"
PlutoTeachingTools = "~0.1.7"
PlutoUI = "~0.7.37"
Query = "~1.0.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.2"
manifest_format = "2.0"
project_hash = "bf40e76d0dd51eeb062fe64d1724c58663897427"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.Adapt]]
deps = ["LinearAlgebra", "Requires"]
git-tree-sha1 = "6a55b747d1812e699320963ffde36f1ebdda4099"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "4.0.4"
weakdeps = ["StaticArrays"]

    [deps.Adapt.extensions]
    AdaptStaticArraysExt = "StaticArrays"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.ArrayInterface]]
deps = ["Adapt", "LinearAlgebra", "Requires", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "c5aeb516a84459e0318a02507d2261edad97eb75"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "7.7.1"

    [deps.ArrayInterface.extensions]
    ArrayInterfaceBandedMatricesExt = "BandedMatrices"
    ArrayInterfaceBlockBandedMatricesExt = "BlockBandedMatrices"
    ArrayInterfaceCUDAExt = "CUDA"
    ArrayInterfaceGPUArraysCoreExt = "GPUArraysCore"
    ArrayInterfaceStaticArraysCoreExt = "StaticArraysCore"
    ArrayInterfaceTrackerExt = "Tracker"

    [deps.ArrayInterface.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    StaticArraysCore = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
    Tracker = "9f7883ad-71c0-57eb-9f7f-b5c9e6d3789c"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9e2a6b69137e6969bab0152632dcb3bc108c8bdd"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+1"

[[deps.CSV]]
deps = ["CodecZlib", "Dates", "FilePathsBase", "InlineStrings", "Mmap", "Parsers", "PooledArrays", "PrecompileTools", "SentinelArrays", "Tables", "Unicode", "WeakRefStrings", "WorkerUtilities"]
git-tree-sha1 = "6c834533dc1fabd820c1db03c839bf97e45a3fab"
uuid = "336ed68f-0bac-5ca0-87d4-7b16caf5d00b"
version = "0.10.14"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "CompilerSupportLibraries_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "a2f1c8c668c8e3cb4cca4e57a8efdb09067bb3fd"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.18.0+2"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra"]
git-tree-sha1 = "71acdbf594aab5bbb2cec89b208c41b4c411e49f"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.24.0"
weakdeps = ["SparseArrays"]

    [deps.ChainRulesCore.extensions]
    ChainRulesCoreSparseArraysExt = "SparseArrays"

[[deps.CodeTracking]]
deps = ["InteractiveUtils", "UUIDs"]
git-tree-sha1 = "7eee164f122511d3e4e1ebadb7956939ea7e1c77"
uuid = "da1fd8a2-8d9e-5ec2-8556-3022fb5608a2"
version = "1.3.6"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "bce6804e5e6044c6daab27bb533d1295e4a2e759"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.6"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "PrecompileTools", "Random"]
git-tree-sha1 = "b5278586822443594ff615963b0c09755771b3e0"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.26.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "b10d0b65641d57b8b4d5e234446582de5047050d"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.5"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "Requires", "Statistics", "TensorCore"]
git-tree-sha1 = "a1f44953f2382ebb937d60dafbe2deea4bd23249"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.10.0"
weakdeps = ["SpecialFunctions"]

    [deps.ColorVectorSpace.extensions]
    SpecialFunctionsExt = "SpecialFunctions"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "362a287c3aa50601b0bc359053d5c2468f0e7ce0"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.11"

[[deps.CommonSubexpressions]]
deps = ["MacroTools"]
git-tree-sha1 = "cda2cfaebb4be89c9084adaca7dd7333369715c5"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.1"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "8ae8d32e09f0dcf42a36b90d4e17f5dd2e4c4215"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.16.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.5+0"

[[deps.ConstructionBase]]
git-tree-sha1 = "76219f1ed5771adbb096743bff43fb5fdd4c1157"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.5.8"

    [deps.ConstructionBase.extensions]
    ConstructionBaseIntervalSetsExt = "IntervalSets"
    ConstructionBaseLinearAlgebraExt = "LinearAlgebra"
    ConstructionBaseStaticArraysExt = "StaticArrays"

    [deps.ConstructionBase.weakdeps]
    IntervalSets = "8197267c-284f-5f27-9208-e0e47529a953"
    LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "abe83f3a2f1b857aac70ef8b269080af17764bbe"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.16.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "db2a9cb664fcea7836da4b414c3278d71dd602d2"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.3.6"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "1d0a14036acb104d9e89698bd408f63ab58cdc82"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.20"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.DataValues]]
deps = ["DataValueInterfaces", "Dates"]
git-tree-sha1 = "d88a19299eba280a6d062e135a43f00323ae70bf"
uuid = "e7dc6d0d-1eca-5fa6-8ad6-5aecde8b7ea5"
version = "0.4.13"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Dbus_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "fc173b380865f70627d7dd1190dc2fce6cc105af"
uuid = "ee1fde0b-3d02-5ea6-8484-8dfef6360eab"
version = "1.14.10+0"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
git-tree-sha1 = "9e2f36d3c96a820c678f2f1f1782582fcf685bae"
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"
version = "1.9.1"

[[deps.DiffResults]]
deps = ["StaticArraysCore"]
git-tree-sha1 = "782dd5f4561f5d267313f23853baaaa4c52ea621"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.1.0"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "23163d55f885173722d1e4cf0f6110cdbaf7e272"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.15.1"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e3290f2d49e661fbd94046d7e3726ffcb2d41053"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.4+0"

[[deps.EpollShim_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8e9441ee83492030ace98f9789a654a6d0b1f643"
uuid = "2702e6a9-849d-5ed8-8c21-79e8b8f9ee43"
version = "0.0.20230411+0"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1c6317308b9dc757616f0b5cb379db10494443a7"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.6.2+0"

[[deps.Extents]]
git-tree-sha1 = "81023caa0021a41712685887db1fc03db26f41f5"
uuid = "411431e0-e8b7-467b-b5e0-f676ba4f2910"
version = "0.1.4"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "PCRE2_jll", "Pkg", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "74faea50c1d007c85837327f6775bea60b5492dd"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.2+2"

[[deps.FilePathsBase]]
deps = ["Compat", "Dates"]
git-tree-sha1 = "7878ff7172a8e6beedd1dea14bd27c3c6340d361"
uuid = "48062228-2e41-5def-b9a4-89aafe57970f"
version = "0.9.22"
weakdeps = ["Mmap", "Test"]

    [deps.FilePathsBase.extensions]
    FilePathsBaseMmapExt = "Mmap"
    FilePathsBaseTestExt = "Test"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "6a70198746448456524cb442b8af316927ff3e1a"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.13.0"

    [deps.FillArrays.extensions]
    FillArraysPDMatsExt = "PDMats"
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStatisticsExt = "Statistics"

    [deps.FillArrays.weakdeps]
    PDMats = "90014a1f-27ba-587c-ab20-58faa44d9150"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.FiniteDiff]]
deps = ["ArrayInterface", "LinearAlgebra", "Requires", "Setfield", "SparseArrays"]
git-tree-sha1 = "73d1214fec245096717847c62d389a5d2ac86504"
uuid = "6a86dc24-6348-571c-b903-95158fe2bd41"
version = "2.22.0"

    [deps.FiniteDiff.extensions]
    FiniteDiffBandedMatricesExt = "BandedMatrices"
    FiniteDiffBlockBandedMatricesExt = "BlockBandedMatrices"
    FiniteDiffStaticArraysExt = "StaticArrays"

    [deps.FiniteDiff.weakdeps]
    BandedMatrices = "aae01518-5342-5314-be14-df237901396f"
    BlockBandedMatrices = "ffab5731-97b5-5995-9138-79e8c1846df0"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Zlib_jll"]
git-tree-sha1 = "db16beca600632c95fc8aca29890d83788dd8b23"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.96+0"

[[deps.Formatting]]
deps = ["Logging", "Printf"]
git-tree-sha1 = "fb409abab2caf118986fc597ba84b50cbaf00b87"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.3"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions"]
git-tree-sha1 = "cf0fe81336da9fb90944683b8c41984b08793dad"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.36"
weakdeps = ["StaticArrays"]

    [deps.ForwardDiff.extensions]
    ForwardDiffStaticArraysExt = "StaticArrays"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "5c1d8ae0efc6c2e7b1fc502cbe25def8f661b7bc"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.13.2+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1ed150b39aebcc805c26b93a8d0122c940f64ce2"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.14+0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll", "libdecor_jll", "xkbcommon_jll"]
git-tree-sha1 = "532f9126ad901533af1d4f5c198867227a7bb077"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.4.0+1"

[[deps.GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "RelocatableFolders", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "c98aea696662d09e215ef7cda5296024a9646c75"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.64.4"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "bc9f7725571ddb4ab2c4bc74fa397c1c5ad08943"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.69.1+0"

[[deps.GeoFormatTypes]]
git-tree-sha1 = "59107c179a586f0fe667024c5eb7033e81333271"
uuid = "68eda718-8dee-11e9-39e7-89f7f65f511f"
version = "0.4.2"

[[deps.GeoInterface]]
deps = ["Extents", "GeoFormatTypes"]
git-tree-sha1 = "5921fc0704e40c024571eca551800c699f86ceb4"
uuid = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"
version = "1.3.6"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "Extents", "GeoInterface", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "b62f2b2d76cee0d61a2ef2b3118cd2a3215d3134"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.11"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE2_jll", "Zlib_jll"]
git-tree-sha1 = "7c82e6a6cd34e9d935e9aa4051b66c6ff3af59ba"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.80.2+0"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "0fa77022fe4b511826b39c894c90daf5fce3334a"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.17"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll"]
git-tree-sha1 = "401e4f3f30f43af2c8478fc008da50096ea5240f"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "8.3.1+0"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.IniFile]]
git-tree-sha1 = "f550e6e32074c939295eb5ea6de31849ac2c9625"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.1"

[[deps.InlineStrings]]
git-tree-sha1 = "45521d31238e87ee9f9732561bfee12d4eebd52d"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.2"

    [deps.InlineStrings.extensions]
    ArrowTypesExt = "ArrowTypes"
    ParsersExt = "Parsers"

    [deps.InlineStrings.weakdeps]
    ArrowTypes = "31f734f8-188a-4ce0-8406-c8a06bd891cd"
    Parsers = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InverseFunctions]]
git-tree-sha1 = "2787db24f4e03daf859c6509ff87764e4182f7d1"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.16"
weakdeps = ["Dates", "Test"]

    [deps.InverseFunctions.extensions]
    InverseFunctionsDatesExt = "Dates"
    InverseFunctionsTestExt = "Test"

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.IterTools]]
git-tree-sha1 = "42d5f897009e7ff2cf88db414a389e5ed1bdd023"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.10.0"

[[deps.IterableTables]]
deps = ["DataValues", "IteratorInterfaceExtensions", "Requires", "TableTraits", "TableTraitsUtils"]
git-tree-sha1 = "70300b876b2cebde43ebc0df42bc8c94a144e1b4"
uuid = "1c8ee90f-4401-5389-894e-7a04a3dc0f4d"
version = "1.0.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "f389674c99bfcde17dc57454011aa44d5a260a40"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.6.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "c84a835e1a09b289ffcd2271bf2a337bbdda6637"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "3.0.3+0"

[[deps.JuliaInterpreter]]
deps = ["CodeTracking", "InteractiveUtils", "Random", "UUIDs"]
git-tree-sha1 = "2984284a8abcfcc4784d95a9e2ea4e352dd8ede7"
uuid = "aa1ae85d-cabe-5617-a682-6adf51b2e16a"
version = "0.9.36"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "170b660facf5df5de098d866564877e119141cbd"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.2+0"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LLVMOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e16271d212accd09d52ee0ae98956b8a05c4b626"
uuid = "1d63c593-3942-5779-bab2-d838dc0a180e"
version = "17.0.6+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "70c5da094887fd2cae843b8db33920bac4b6f07d"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.2+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "50901ebc375ed41dbf8058da26f9de442febbbec"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.1"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "OrderedCollections", "Printf", "Requires"]
git-tree-sha1 = "8c57307b5d9bb3be1ff2da469063628631d4d51e"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.21"

    [deps.Latexify.extensions]
    DataFramesExt = "DataFrames"
    DiffEqBiologicalExt = "DiffEqBiological"
    ParameterizedFunctionsExt = "DiffEqBase"
    SymEngineExt = "SymEngine"

    [deps.Latexify.weakdeps]
    DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
    DiffEqBase = "2b5f629d-d688-5b77-993f-72d75c75574e"
    DiffEqBiological = "eb300fae-53e8-50a0-950c-e21f52c2b7e0"
    SymEngine = "123dc426-2d89-5057-bbad-38513e3affd8"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll"]
git-tree-sha1 = "9fd170c4bbfd8b935fdc5f8b7aa33532c991a673"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.11+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "6f73d1dd803986947b2c750138528a999a6c7733"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.6.0+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "fbb1f2bef882392312feb1ede3615ddc1e9b99ed"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.49.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "f9557a255370125b405568f9767d6d195822a175"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.17.0+0"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "0c4f9c4f1a50d8f35048fa0532dabbadf702f81e"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.40.1+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "3eb79b0ca5764d4799c06699573fd8f533259713"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.4.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "5ee6203157c120d79034c748a2acba45b82b8807"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.40.1+0"

[[deps.LineSearches]]
deps = ["LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "Printf"]
git-tree-sha1 = "e4c3be53733db1051cc15ecf573b1042b3a712a1"
uuid = "d3d80556-e9d4-5f37-9878-2ab0fcc64255"
version = "7.3.0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "a2d09619db4e765091ee5c6ffe8872849de0feea"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.28"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoweredCodeUtils]]
deps = ["JuliaInterpreter"]
git-tree-sha1 = "c2b5e92eaf5101404a58ce9c6083d595472361d6"
uuid = "6f1432cf-f94c-5a45-995e-cdbf5db27b0b"
version = "3.0.2"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "2fa9ee3e63fd3a4f7a9a4f4744a52f4856de82df"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.13"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "NetworkOptions", "Random", "Sockets"]
git-tree-sha1 = "c067a280ddc25f196b5e7df3877c6b226d390aaf"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.9"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+0"

[[deps.Measures]]
git-tree-sha1 = "c13304c81eec1ed3af7fc20e75fb6b26092a1102"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.2"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "ec4f7fbeab05d7747bdf98eb74d130a2a2ed298d"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.2.0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.10.11"

[[deps.NLSolversBase]]
deps = ["DiffResults", "Distributed", "FiniteDiff", "ForwardDiff"]
git-tree-sha1 = "a0b464d183da839699f4c79e7606d9d186ec172c"
uuid = "d41bc354-129a-5804-8e4c-c37616107c6c"
version = "7.8.3"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.21+4"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "a12e56c72edee3ce6b96667745e6cbbe5498f200"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.23+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Optim]]
deps = ["Compat", "FillArrays", "ForwardDiff", "LineSearches", "LinearAlgebra", "NLSolversBase", "NaNMath", "Parameters", "PositiveFactorizations", "Printf", "SparseArrays", "StatsBase"]
git-tree-sha1 = "01f85d9269b13fedc61e63cc72ee2213565f7a72"
uuid = "429524aa-4258-5aef-a3af-852621145aeb"
version = "1.7.8"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6703a85cb3781bd5909d48730a67205f3f31a575"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.3+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "dfdf5519f235516220579f949664f1bf44e741c5"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.3"

[[deps.PCRE2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "efcefdf7-47ab-520b-bdef-62a2eaa19f15"
version = "10.42.0+0"

[[deps.Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e127b609fb9ecba6f201ba7ab753d5a605d53801"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.54.1+0"

[[deps.ParameterHandling]]
deps = ["ChainRulesCore", "Compat", "InverseFunctions", "IterTools", "LinearAlgebra", "LogExpFunctions", "SparseArrays", "Test"]
git-tree-sha1 = "11bb9d2aaa7113031456cfe8f100e7a587e18ebf"
uuid = "2412ca09-6db7-441c-8e3a-88d5709968c5"
version = "0.4.10"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "8489905bcdbcfac64d1daa51ca07c0d8f0283821"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.1"

[[deps.Pixman_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "LLVMOpenMP_jll", "Libdl"]
git-tree-sha1 = "35621f10a7531bc8fa58f74610b1bfb70a3cfc6b"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.43.4+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.2"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Requires", "Statistics"]
git-tree-sha1 = "a3a964ce9dc7898193536002a6dd892b1b5a6f1d"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "2.0.1"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "PrecompileTools", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "7b1a9df27f072ac4c9c7cbe5efb198489258d1f5"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.4.1"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "GeometryBasics", "JSON", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "Unzip"]
git-tree-sha1 = "2f041202ab4e47f4a3465e3993929538ea71bd48"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.26.1"

[[deps.PlutoHooks]]
deps = ["InteractiveUtils", "Markdown", "UUIDs"]
git-tree-sha1 = "072cdf20c9b0507fdd977d7d246d90030609674b"
uuid = "0ff47ea0-7a50-410d-8455-4348d5de0774"
version = "0.0.5"

[[deps.PlutoLinks]]
deps = ["FileWatching", "InteractiveUtils", "Markdown", "PlutoHooks", "Revise", "UUIDs"]
git-tree-sha1 = "8f5fa7056e6dcfb23ac5211de38e6c03f6367794"
uuid = "0ff47ea0-7a50-410d-8455-4348d5de0420"
version = "0.1.6"

[[deps.PlutoTeachingTools]]
deps = ["Downloads", "HypertextLiteral", "LaTeXStrings", "Latexify", "Markdown", "PlutoLinks", "PlutoUI", "Random"]
git-tree-sha1 = "67c917d383c783aeadd25babad6625b834294b30"
uuid = "661c6b06-c737-4d37-b85c-46df65de6f69"
version = "0.1.7"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "eba4810d5e6a01f612b948c9fa94f905b49087b0"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.60"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "36d8b4b899628fb92c2749eb488d884a926614d3"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.3"

[[deps.PositiveFactorizations]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "17275485f373e6673f7e7f97051f703ed5b15b20"
uuid = "85a6dd25-e78a-55b7-8502-1745935b8125"
version = "0.2.4"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "9306f6085165d270f7e3db02af26a400d580f5c6"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.3"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "dfb54c4e414caa595a1f2ed759b160f5a3ddcba5"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.3.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "0c03844e2231e12fda4d0086fd7cbe4098ee8dc5"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+2"

[[deps.Query]]
deps = ["DataValues", "IterableTables", "MacroTools", "QueryOperators", "Statistics"]
git-tree-sha1 = "a66aa7ca6f5c29f0e303ccef5c8bd55067df9bbe"
uuid = "1a8c2f83-1ff3-5112-b086-8aa67b057ba1"
version = "1.0.0"

[[deps.QueryOperators]]
deps = ["DataStructures", "DataValues", "IteratorInterfaceExtensions", "TableShowUtils"]
git-tree-sha1 = "911c64c204e7ecabfd1872eb93c49b4e7c701f02"
uuid = "2aef5ad7-51ca-5a8f-8e88-e75cf067b44b"
version = "0.9.3"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RecipesBase]]
deps = ["PrecompileTools"]
git-tree-sha1 = "5c3d09cc4f31f5fc6af001c250bf1278733100ff"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.3.4"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "dc1e451e15d90347a7decc4221842a022b011714"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.5.2"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "cdbd3b1338c72ce29d9584fdbe9e9b70eeb5adca"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "0.1.3"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Revise]]
deps = ["CodeTracking", "Distributed", "FileWatching", "JuliaInterpreter", "LibGit2", "LoweredCodeUtils", "OrderedCollections", "REPL", "Requires", "UUIDs", "Unicode"]
git-tree-sha1 = "7b7850bb94f75762d567834d7e9802fc22d62f9c"
uuid = "295af30f-e4ad-537b-8983-00126c2a3abe"
version = "3.5.18"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "3bac05bc7e74a75fd9cba4295cde4045d9fe2386"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.2.1"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "ff11acffdb082493657550959d4feb4b6149e73a"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.5"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "e2cc6d8c88613c05e1defb55170bf5ff211fbeac"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.1"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "66e0a8e672a0bdfca2c3f5937efb8538b9ddc085"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.2.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "2f5d4697f21388cbe1ff299430dd169ef97d7e14"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.4.0"
weakdeps = ["ChainRulesCore"]

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "PrecompileTools", "Random", "StaticArraysCore"]
git-tree-sha1 = "eeafab08ae20c62c44c8399ccb9354a04b80db50"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.9.7"
weakdeps = ["ChainRulesCore", "Statistics"]

    [deps.StaticArrays.extensions]
    StaticArraysChainRulesCoreExt = "ChainRulesCore"
    StaticArraysStatisticsExt = "Statistics"

[[deps.StaticArraysCore]]
git-tree-sha1 = "192954ef1208c7019899fbf8049e717f92959682"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.3"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1ff449ad350c9c4cbc756624d6f8a8c3ef56d3ed"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.7.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[deps.StructArrays]]
deps = ["ConstructionBase", "DataAPI", "Tables"]
git-tree-sha1 = "f4dc295e983502292c4c3f951dbb4e985e35b3be"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.18"

    [deps.StructArrays.extensions]
    StructArraysAdaptExt = "Adapt"
    StructArraysGPUArraysCoreExt = "GPUArraysCore"
    StructArraysSparseArraysExt = "SparseArrays"
    StructArraysStaticArraysExt = "StaticArrays"

    [deps.StructArrays.weakdeps]
    Adapt = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "5.10.1+6"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableShowUtils]]
deps = ["DataValues", "Dates", "JSON", "Markdown", "Unicode"]
git-tree-sha1 = "2a41a3dedda21ed1184a47caab56ed9304e9a038"
uuid = "5e66a065-1f0a-5976-b372-e0b8c017ca10"
version = "0.2.6"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.TableTraitsUtils]]
deps = ["DataValues", "IteratorInterfaceExtensions", "Missings", "TableTraits"]
git-tree-sha1 = "78fecfe140d7abb480b53a44f3f85b6aa373c293"
uuid = "382cd787-c1b6-5bf2-a167-d5b971a19bda"
version = "1.0.2"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "OrderedCollections", "TableTraits"]
git-tree-sha1 = "598cd7c1f68d1e205689b1c2fe65a9f85846f297"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.12.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TranscodingStreams]]
git-tree-sha1 = "e84b3a11b9bece70d14cce63406bbc79ed3464d2"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.11.2"

[[deps.Tricks]]
git-tree-sha1 = "7822b97e99a1672bfb1b49b668a6d46d58d8cbcb"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.9"

[[deps.URIs]]
git-tree-sha1 = "67db6cc7b3821e19ebe75791a9dd19c9b1188f2b"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.5.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unzip]]
git-tree-sha1 = "34db80951901073501137bdbc3d5a8e7bbd06670"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.1.2"

[[deps.Wayland_jll]]
deps = ["Artifacts", "EpollShim_jll", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "7558e29847e99bc3f04d6569e82d0f5c54460703"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.21.0+1"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "93f43ab61b16ddfb2fd3bb13b3ce241cafb0e6c9"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.31.0+0"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.WorkerUtilities]]
git-tree-sha1 = "cd1659ba0d57b71a464a29e64dbc67cfe83d54e7"
uuid = "76eceee3-57b5-4d4a-8e66-0e911cebbf60"
version = "1.6.1"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Zlib_jll"]
git-tree-sha1 = "1165b0443d0eca63ac1e32b8c0eb69ed2f4f8127"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.13.3+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "a54ee957f4c86b526460a720dbc882fa5edcbefc"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.41+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "afead5aba5aa507ad5a3bf01f58f82c8d1403495"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.8.6+0"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "6035850dcc70518ca32f012e46015b9beeda49d8"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.11+0"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "34d526d318358a859d7de23da945578e8e8727b7"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.4+0"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "d2d1a5c49fae4ba39983f63de6afcbea47194e85"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.6+0"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "47e45cd78224c53109495b3e324df0c37bb61fbe"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.11+0"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8fdda4c692503d44d04a0603d9ac0982054635f9"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.1+0"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "bcd466676fef0878338c61e655629fa7bbc69d8e"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.17.0+0"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libX11_jll"]
git-tree-sha1 = "730eeca102434283c50ccf7d1ecdadf521a765a4"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.2+0"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "330f955bc41bb8f5270a369c473fc4a5a4e4d3cb"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.6+0"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "691634e5453ad362044e2ad653e79f3ee3bb98c3"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.39.0+0"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e92a1a012a10506618f10b7047e478403a046c77"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.5.0+0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+0"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "e678132f07ddb5bfa46857f0d7620fb9be675d3b"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.6+0"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "1827acba325fdcdf1d2647fc8d5301dd9ba43a9d"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.9.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "e17c115d55c5fbb7e52ebedb427a0dca79d4484e"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.2+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+0"

[[deps.libdecor_jll]]
deps = ["Artifacts", "Dbus_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pango_jll", "Wayland_jll", "xkbcommon_jll"]
git-tree-sha1 = "9bf7903af251d2050b467f76bdbe57ce541f7f4f"
uuid = "1183f4f0-6f2a-5f1a-908b-139f9cdfea6f"
version = "0.2.2+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "8a22cf860a7d27e4f3498a0fe0811a7957badb38"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.3+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Zlib_jll"]
git-tree-sha1 = "d7015d2e18a5fd9a4f47de711837e980519781a4"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.43+1"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "490376214c4721cdaca654041f635213c6165cb3"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+2"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "9c304562909ab2bab0262639bd4f444d7bc2be37"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+1"
"""

# ╔═╡ Cell order:
# ╟─82d5eb4f-5724-4c72-b6e0-f6d5fc7f4313
# ╟─57141374-dd5a-4eaa-8235-b2310ef2d600
# ╟─c516e3bd-0858-498f-9db8-94395ad72ea0
# ╟─6be0b0bf-24e3-417c-a257-c4f61a31e1e3
# ╟─4eace0ad-5222-4e1d-9760-7e139478e866
# ╟─8bc702c6-b3b2-4a81-901c-ce361b8c10e5
# ╟─637a5d00-0e91-4227-aac5-829094935d91
# ╟─4d4d3ea6-3d87-4ec3-9625-7ba00e17dbcf
# ╟─8d0a2a57-1bbe-4145-9e1b-de125c7635ef
# ╟─bab9033c-b9ee-45c1-9466-838e40bdb920
# ╟─4bdcca25-c37f-4079-b222-be773adc2b8f
# ╟─ee7aaab9-5e4f-46ab-8100-75be142fba72
# ╟─2306a2d5-2924-45e0-adec-b90d536d2949
# ╟─3d1821a6-f134-49d6-a4b0-39d6d28ab420
# ╠═873c94d4-29f1-4664-87b1-d70615c0f8ed
# ╟─5a73b1fc-99bc-4530-ae4a-49ce25df99dc
# ╟─253decc1-35c7-4454-b500-4f28e1087d36
# ╟─5edc2a2d-6f63-4ac6-8c33-2c5d670bc466
# ╟─21834080-14de-4926-9766-5a3ad994e2a1
# ╟─fcf19e04-3e35-4a01-8036-fd5b283fdd37
# ╟─d2d1cf44-255a-47bf-ba3d-42169c6af060
# ╟─49fdca20-46fd-4f31-94f1-ed58f3b32305
# ╠═a318c478-f71c-457b-9c54-fe69e964849a
# ╟─41b2eea0-3049-4fa5-803e-83a54b74ef27
# ╟─84c68b29-6707-4761-bde1-2dcabe5a0ac9
# ╟─fa3fe244-75cf-434b-8de1-5fca5db06c8b
# ╟─43ae8d15-6381-4c86-b08d-2d12cd4bc653
# ╟─278d1fbd-7c64-4544-b37a-8258f493b3db
# ╟─55034abb-34e3-4fab-9b80-c82019a67756
# ╟─fac9b01f-3a92-49da-9ec9-2e6502d595d9
# ╠═26c601fb-d62f-47f2-a7ff-e7ca63ad9dcd
# ╟─a847e31d-9007-478b-b1e3-ffb8e55a6f3c
# ╟─abc38d23-8665-4377-9a25-9e9c5a10a7bf
# ╟─844ede38-9596-47a6-b30b-9eff622a2330
# ╟─de533ac4-6870-40f8-8bad-f8c62694e719
# ╟─bc0d6fd6-de10-4c58-b55c-7bca8fbc123a
# ╟─dbc0e11e-d3e0-46a4-92c5-3afc31463c03
# ╟─f0febfcd-f0f9-4ce8-a3ab-673ad2f19e5a
# ╟─1b260d22-e035-4991-bd42-4abd6f6b0333
# ╟─849d5f32-f7c4-45cf-bc9d-85eae6c13d4f
# ╟─449a4faf-0ba8-4325-a902-427951c60036
# ╟─b60aadbc-4e70-414e-9fdc-c3b042cb17bf
# ╠═8be9bf52-a0a3-11ec-045f-3962ad227049
# ╟─8c1ed181-6386-4c55-ba87-18354b6f02b5
# ╟─c3a9ed24-93a0-4cec-8233-3a93be5408f3
# ╟─69f40924-6b24-4014-8c1b-f600a0759aab
# ╠═3fbcc50d-9f6a-4aec-9a8f-f2f525223f0e
# ╠═a7514405-af4c-4f16-8508-91ee624d8a1c
# ╠═690205fb-0b95-4614-9b66-dec362ed693c
# ╠═4f047081-a4d6-414b-9c3e-0eb055c730b3
# ╠═8f700e72-df0f-4e68-85fe-7fbe8da7fbb1
# ╟─7047d464-efdd-4315-b930-5b2e8a3d93c5
# ╠═cc7006c7-e3ef-470a-b93e-5743a27a32d9
# ╠═5677766e-6466-4b0b-b703-61f9aaaf5cd3
# ╠═56d09fea-e2c2-4345-a089-419ac863ac43
# ╠═19a96558-4c9f-4bad-8fc2-735c813bd756
# ╠═3932fb9d-2897-4d64-8dba-a51799d1aa7a
# ╟─d4e5cd92-21c0-4073-ab3e-8cd5804976c8
# ╟─9da83c61-cbcb-4c13-83d1-21a26b1c59d1
# ╟─ba141b21-ab58-400a-a41a-9cdd4dd5987d
# ╟─393c7568-a234-4ef5-97a6-4af630e355e5
# ╟─d5febe7d-bf9b-4793-96f3-9c31b641b3ae
# ╟─2e51744b-b040-4f21-94b8-ffe9cd1e149e
# ╟─5e92054a-ca9e-4949-9727-5a9ed14003c0
# ╟─bce3f35c-07a1-48ef-8a29-243b2215fcb5
# ╟─8b1f8b91-12b5-4e61-a8ff-63538189cf34
# ╟─93d115f3-ab51-4425-8bc8-33dc9b37bd87
# ╟─ad74edd0-5056-48f6-9f5c-19a46c0b7277
# ╟─d5036d21-76b3-41f9-8c34-59c8afe9ffe2
# ╟─bc7e067b-a170-40e0-b9f1-11b097e72a09
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
