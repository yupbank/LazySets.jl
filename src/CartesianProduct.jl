import Base:*, ×, ∈

export CartesianProduct,
       CartesianProductArray

"""
    CartesianProduct{N<:Real, S1<:LazySet{N}, S2<:LazySet{N}} <: LazySet{N}

Type that represents a Cartesian product of two convex sets.

### Fields

- `X` -- first convex set
- `Y` -- second convex set

### Notes

The Cartesian product of three elements is obtained recursively.
See also `CartesianProductArray` for an implementation of a Cartesian product of
many sets without recursion, instead using an array.

- `CartesianProduct{N<:Real, S1<:LazySet{N}, S2<:LazySet{N}}(X1::S1, X2::S2)`
  -- default constructor

- `CartesianProduct(Xarr::Vector{S}) where {S<:LazySet}`
  -- constructor from an array of convex sets
"""
struct CartesianProduct{N<:Real, S1<:LazySet{N}, S2<:LazySet{N}} <: LazySet{N}
    X::S1
    Y::S2
end
# type-less convenience constructor
CartesianProduct(X1::S1, X2::S2
                ) where {S1<:LazySet{N}, S2<:LazySet{N}} where {N<:Real} =
    CartesianProduct{N, S1, S2}(X1, X2)
# constructor from an array
CartesianProduct(Xarr::Vector{S}) where {S<:LazySet{N}} where {N<:Real} =
    (length(Xarr) == 0
        ? EmptySet{N}()
        : length(Xarr) == 1
            ? Xarr[1]
            : length(Xarr) == 2
                ? CartesianProduct(Xarr[1], Xarr[2])
                : CartesianProduct(Xarr[1],
                                   CartesianProduct(Xarr[2:length(Xarr)])))

"""
```
    *(X::LazySet, Y::LazySet)::CartesianProduct
```

Return the Cartesian product of two convex sets.

### Input

- `X` -- convex set
- `Y` -- convex set

### Output

The Cartesian product of the two convex sets.
"""
*(X::LazySet, Y::LazySet)::CartesianProduct = CartesianProduct(X, Y)

"""
    ×

Alias for the binary Cartesian product.
"""
×(X::LazySet, Y::LazySet) = *(X, Y)

"""
    X × ∅

Right multiplication of a set by an empty set.

### Input

- `X` -- a convex set
- `∅` -- an empty set

### Output

An empty set, because the empty set is the absorbing element for the
Cartesian product.
"""
*(::LazySet, ∅::EmptySet) = ∅

"""
    ∅ × X

Left multiplication of a set by an empty set.

### Input

- `X` -- a convex set
- `∅` -- an empty set

### Output

An empty set, because the empty set is the absorbing element for the
Cartesian product.
"""
*(∅::EmptySet, ::LazySet) = ∅

# special case: pure empty set multiplication (we require the same numeric type)
(*(∅::E, ::E)) where {E<:EmptySet} = ∅

"""
    dim(cp::CartesianProduct)::Int

Return the dimension of a Cartesian product.

### Input

- `cp` -- Cartesian product

### Output

The ambient dimension of the Cartesian product.
"""
function dim(cp::CartesianProduct)::Int
    return dim(cp.X) + dim(cp.Y)
end

"""
    σ(d::AbstractVector{<:Real}, cp::CartesianProduct)::AbstractVector{<:Real}

Return the support vector of a Cartesian product.

### Input

- `d`  -- direction
- `cp` -- Cartesian product

### Output

The support vector in the given direction.
If the direction has norm zero, the result depends on the product sets.
"""
function σ(d::AbstractVector{<:Real},
           cp::CartesianProduct)::AbstractVector{<:Real}
    return [σ(view(d, 1:dim(cp.X)), cp.X);
            σ(view(d, dim(cp.X)+1:length(d)), cp.Y)]
end

"""
    ∈(x::AbstractVector{<:Real}, cp::CartesianProduct)::Bool

Check whether a given point is contained in a Cartesian product set.

### Input

- `x`  -- point/vector
- `cp` -- Cartesian product

### Output

`true` iff ``x ∈ cp``.
"""
function ∈(x::AbstractVector{<:Real}, cp::CartesianProduct)::Bool
    @assert length(x) == dim(cp)

    return ∈(view(x, 1:dim(cp.X)), cp.X) &&
           ∈(view(x, dim(cp.X)+1:length(x)), cp.Y)
end

# ======================================
#  Cartesian product of an array of sets
# ======================================
"""
    CartesianProductArray{N<:Real, S<:LazySet{N}} <: LazySet{N}

Type that represents the Cartesian product of a finite number of convex sets.

### Fields

- `sfarray` -- array of sets

### Notes

- `CartesianProductArray(sfarray::Vector{<:LazySet})` -- default constructor

- `CartesianProductArray()` -- constructor for an empty Cartesian product

- `CartesianProductArray(n::Int, [N]::Type=Float64)`
  -- constructor for an empty Cartesian product with size hint and numeric type
"""
struct CartesianProductArray{N<:Real, S<:LazySet{N}} <: LazySet{N}
    sfarray::Vector{S}
end
# type-less convenience constructor
CartesianProductArray(arr::Vector{S}) where {S<:LazySet{N}} where {N<:Real} =
    CartesianProductArray{N, S}(arr)
# constructor for an empty Cartesian product of floats
CartesianProductArray() =
    CartesianProductArray{Float64, LazySet{Float64}}(Vector{LazySet{Float64}}(0))
# constructor for an empty Cartesian product with size hint and numeric type
function CartesianProductArray(n::Int, N::Type=Float64)::CartesianProductArray
    arr = Vector{LazySet{N}}(0)
    sizehint!(arr, n)
    return CartesianProductArray(arr)
end

"""
```
    *(cpa::CartesianProductArray, S::LazySet)::CartesianProductArray
```

Multiply a convex set to a Cartesian product of a finite number of convex sets
from the right.

### Input

- `cpa` -- Cartesian product array (is modified)
- `S`   -- convex set

### Output

The modified Cartesian product of a finite number of convex sets.
"""
function *(cpa::CartesianProductArray, S::LazySet)::CartesianProductArray
    push!(cpa.sfarray, S)
    return cpa
end

"""
```
    *(S::LazySet, cpa::CartesianProductArray)::CartesianProductArray
```

Multiply a convex set to a Cartesian product of a finite number of convex sets
from the left.

### Input

- `S`   -- convex set
- `cpa` -- Cartesian product array (is modified)

### Output

The modified Cartesian product of a finite number of convex sets.
"""
function *(S::LazySet, cpa::CartesianProductArray)::CartesianProductArray
    push!(cpa.sfarray, S)
    return cpa
end

"""
```
    *(cpa::CartesianProductArray, ∅::EmptySet)
```

Right multiplication of a `CartesianProductArray` by an empty set.

### Input

- `cpa` -- Cartesian product array
- `∅`   -- an empty set

### Output

An empty set, because the empty set is the absorbing element for the
Cartesian product.
"""
*(::CartesianProductArray, ∅::EmptySet) = ∅

"""
```
    *(S::EmptySet, cpa::CartesianProductArray)
```

Left multiplication of a set by an empty set.

### Input

- `X` -- a convex set
- `∅` -- an empty set

### Output

An empty set, because the empty set is the absorbing element for the
Cartesian product.
"""
*(∅::EmptySet, ::CartesianProductArray) = ∅

"""
```
    *(cpa1::CartesianProductArray, cpa2::CartesianProductArray)::CartesianProductArray
```

Multiply a finite Cartesian product of convex sets to another finite Cartesian
product.

### Input

- `cpa1` -- first Cartesian product array (is modified)
- `cpa2` -- second Cartesian product array

### Output

The modified first Cartesian product.
"""
function *(cpa1::CartesianProductArray,
           cpa2::CartesianProductArray)::CartesianProductArray
    append!(cpa1.sfarray, cpa2.sfarray)
    return cpa1
end

"""
    dim(cpa::CartesianProductArray)::Int

Return the dimension of a Cartesian product of a finite number of convex sets.

### Input

- `cpa` -- Cartesian product array

### Output

The ambient dimension of the Cartesian product of a finite number of convex
sets.
"""
function dim(cpa::CartesianProductArray)::Int
    return length(cpa.sfarray) == 0 ? 0 : sum([dim(sj) for sj in cpa.sfarray])
end

"""
    σ(d::AbstractVector{<:Real}, cpa::CartesianProductArray)::AbstractVector{<:Real}

Support vector of a Cartesian product.

### Input

- `d`   -- direction
- `cpa` -- Cartesian product array

### Output

The support vector in the given direction.
If the direction has norm zero, the result depends on the product sets.
"""
function σ(d::AbstractVector{<:Real},
           cpa::CartesianProductArray)::AbstractVector{<:Real}
    svec = similar(d)
    jinit = 1
    for sj in cpa.sfarray
        jend = jinit + dim(sj) - 1
        svec[jinit:jend] = σ(d[jinit:jend], sj)
        jinit = jend + 1
    end
    return svec
end

"""
    ∈(x::AbstractVector{<:Real}, cpa::CartesianProductArray)::Bool

Check whether a given point is contained in a Cartesian product of a finite
number of sets.

### Input

- `x`   -- point/vector
- `cpa` -- Cartesian product array

### Output

`true` iff ``x ∈ \\text{cpa}``.
"""
function ∈(x::AbstractVector{<:Real}, cpa::CartesianProductArray)::Bool
    @assert length(x) == dim(cpa)

    jinit = 1
    for sj in cpa
        jend = jinit + dim(sj) - 1
        if !∈(x[jinit:jend], sj)
            return false
        end
        jinit = jend + 1
    end
    return true
end
