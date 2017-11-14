#!/usr/bin/env julia

#= This code will generate a psdpdf from a set of timeseries using the multitaper
method. See below for input arguments or enter into the command line:
        $ multitaper_psdpdf.jl -h


The script will read a directory of SAC files or a single SAC file. For a single
file, the seismogram will be split into a set of equal length seismograms that are
overlapping in time and stored in an array and saved as a csv file. The
multitaper is computed for each column of the array and the median is computed
along with confidence intervals.

=#


#= ----------------------------------------------------------------------------
# We want to pass arguments to the script via command line but they need to be
identified so we know the work order =#
using ArgParse, SAC, DSP, KernelDensity

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table s begin
        "-f"
            help = "Input Filename"
        "-d"
            help = "Input Directory"
        "-t"
            help = "Input File Type (SAC,csv)"

        "-P"
            help = "Plot the results (1/0)"
            arg_type = Int
            default = 0
        "-o"
            help = "Output Filename"
            default = "psdpdf.csv"
        "-n"
            help = "N Overlap"
            arg_type = Int
            default = 0
        "-l"
            help = "Segment Length"
            arg_type = Int
    end

    return parse_args(s)
end


function main()
    parsed_args = parse_commandline()
end

p = main()




# ----------------------------------------------------------------------------

function mtap_psdpdf_sacfn(filename, Params)
#=
SAC files contain header values that allow more automated processing
=#

end

function mtap_psd_sacdir(dirname)
#=
Just like the single fn function above. We can read the full directory

Input Variables:
    dirname - the name of the directory to be processed
              (e.g. ""/Name/Of/Directory/*.SAC")
=#
    T, filename = read_wild(dirname)
    n = length(T)
    nw = 4
    ntapers = maximum([4, (2*nw-1)])

    freq = []
    power = []

    for i = 1:n
        ts = T[i].t
        fs = round(1/T[i].delta )
        # We want padding to eliminate edge effects
        m = length(ts)
        winfun = dpss(m, nw, ntapers  )
        nfft = Int( 2^(round(log2(m)) + 1) )
        mta = mt_pgram( ts; fs=fs, nw=nw, nfft=nfft, window = winfun    )
        freq = vcat(freq, mta.freq)
        power = vcat( power, 10*log10(mta.power) )
    end

    power = power[freq .!= 0.0 ]
    freq = freq[freq .!= 0.0 ]

    freq, power
end



# ----------------------------------------------------------------------------


# Open libraries
using DataFrames, DSP



#input_file = ARGS[1]
input_file = "trace_matrix.csv"

# output_file = ARGS[2]

df = readtable(input_file, separator = ',', header = false)
m = size(df,1)

# get the sampling rate
dt = df[1,:]

df = df[5:m, :]


=#


# ----------------------------------------------------------------------------

##!! These functions may become obsolete !!##

function freq_bin_gen(fs, dec_oct, min_df)
#=
    This generates bins based on an octave change
=#
    bin = fs/2

    nfs = fs/2
    while nfs > min_df
        nfs = nfs*dec_oct
        #print(nfs)
        bin = hcat(bin, nfs)
    end
    return(bin)

end



function power_bin_gen(plims, nbins)
#=

=#
    bins = linspace(plims[1], plims[2], nbins)
end


# ----------------------------------------------------------------------------

function psdpdf( freq_power, fb_params, pb_params )
#=
=#
    #=
    fbins = freq_bin_gen(fb_params[1], fb_params[2], fb_params[3] )
    pbins = power_bin_gen(pb_params[1], pb_params[2] )
    fbins, pbins, counts = hist2d(freq_power, vec(fbins), vec(pbins) )

    m = length(pbins)
    n = length(fbins)

    for i = 1:n

    end

    return(counts)
    =#

    density_kde = kde(freq_power)



end

# --------------------------- Compute the PSDPDF ----------------------------- #



if p["d"] != nothing && p["t"] == "SAC"
    dirname = string(p["d"], "*.SAC")
    freq, power = mtap_psd_sacdir(dirname)
elseif p["f"] != nothing #!! NOT YET IMPLEMENTED
    filename = p["f"]
    Params = [ p["o"], p["n"], p["l"] ]
    freq, power = mtap_psd_sacfn(filename, Params)
else
    error("Specify an input file or directory.")
end

fb_params = [fs, dec_oct, minimum(freq)]
pb_params = [floor(minimum(power))-5, ceil(maximum(power))+5 ]

counts = psdpdf( hcat(vec(freq), vec(10*log10(power) ), fb_params, pb_params)
