# 24 Oct 2026: no line may carry code after a `#` comment. Twice this week a comment placed mid-line swallowed the rest of a
# NamedTuple (18 Oct: eighteen ladder rules; 23 Oct: V8's initial prices). A continuation line of a literal that ends in "," or
# "(" after the comment, or a comment followed by `name = value,` is the signature; the test fails on it.
using Test
let hits = String[]
    for dir in ("src", "scripts"), f in readdir(joinpath(@__DIR__, "..", dir); join = true)
        endswith(f, ".jl") || continue
        for (i, line) in enumerate(eachline(f))
            stripped = lstrip(line)
            (startswith(stripped, "#") || !occursin('#', line)) && continue
            code, comment = split(line, '#'; limit = 2)
            occursin(r"\w+\s*=\s*[^,#]+,\s*$", comment) && occursin(r"(\(;|,)\s*$", rstrip(code)) && push!(hits, "$(basename(f)):$i")
        end
    end
    @test isempty(hits) || error("code after a comment (a swallowed tail): " * join(hits, ", "))
end
