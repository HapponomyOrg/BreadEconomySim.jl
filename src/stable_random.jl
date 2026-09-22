# ---- version-stable randomness (23 September 2026) ----------------------------------------------------------------------
#
# Julia does not promise the same random sequence across versions: its default generator, `shuffle`, `rand(collection)`,
# `rand(1:n)` and `hash` may all change between releases, so a seed that reproduced a run on Julia 1.12 did not on 1.13.
# Everything random in the model goes through the functions in this file instead:
#   - every stream is a `StableRNG` (StableRNGs.jl guarantees its `rand(rng)` sequence across Julia versions);
#   - a stream's seed comes from the run seed and the stream's name by a fixed rule written here (FNV-1a and SplitMix64),
#     not from `hash`;
#   - picking, shuffling and drawing from a range use only `rand(rng)`, through the helpers below.
# With this, and with every dictionary the model iterates being an insertion-ordered `OrderedDict`, a seed gives the same
# run on any Julia version and any processor.

"""FNV-1a hash of a name — a fixed rule, unlike Julia's `hash`, which may change between versions."""
function fnv1a(s::AbstractString)
    h = 0xcbf29ce484222325
    for b in codeunits(s)
        h = (h ⊻ UInt64(b)) * 0x100000001b3
    end
    return h
end

"""SplitMix64 finaliser: spreads the bits of a 64-bit number."""
function splitmix64(x::UInt64)
    x += 0x9e3779b97f4a7c15
    x = (x ⊻ (x >> 30)) * 0xbf58476d1ce4e5b9
    x = (x ⊻ (x >> 27)) * 0x94d049bb133111eb
    return x ⊻ (x >> 31)
end

"""The seed of a subsystem's stream: the run seed and the stream's name, combined by a fixed rule."""
stream_seed(seed::Integer, name::Symbol) = splitmix64(fnv1a(String(name)) ⊻ splitmix64(UInt64(seed)))

"""A uniform index in 1:n from a single `rand(rng)` draw."""
stable_index(rng, n::Integer) = min(floor(Int, rand(rng) * n) + 1, n)

"""A uniform element of a non-empty vector."""
stable_pick(rng, v::AbstractVector) = v[stable_index(rng, length(v))]

"""A uniform integer in a range."""
stable_range(rng, r::AbstractUnitRange{<:Integer}) = first(r) + stable_index(rng, length(r)) - 1

"""Fisher–Yates shuffle in place, using only `rand(rng)`."""
function stable_shuffle!(rng, v::AbstractVector)
    for i in length(v):-1:2
        j = stable_index(rng, i)
        v[i], v[j] = v[j], v[i]
    end
    return v
end

"""A shuffled copy."""
stable_shuffle(rng, v::AbstractVector) = stable_shuffle!(rng, collect(v))

"""Every agent, dead or alive, in the order of their ids (Agents.jl keeps agents in a hash map whose order may change)."""
agents_by_id(model) = sort!(collect(allagents(model)); by = a -> a.id)
