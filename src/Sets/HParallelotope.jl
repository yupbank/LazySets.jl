export HParallelotope,
       directions,
       offset,
       dim,
       base_vertex,
       extremal_vertices,
       center,
       genmat,
       generators,
       constraints_list

"""
    HParallelotope{N<:Real, VN<:AbstractVector{N}, MN<:AbstractMatrix{N}} <: AbstractZonotope{N}

Type that represents a parallelotope in constraint form.

### Fields

- `directions` -- square matrix such that each row is the direction of two parallel constraints
- `offset`     -- vector such that each element is the offset of the corresponding constraint

### Notes

Parallelotopes are centrally symmetric convex polytopes in ``\\mathbb{R}^n`` having
``2n`` pairwise parallel constraints. Every parallelotope is a zonotope.
As such, parallelotopes can be represented either in constraint form or in
generator form. The `HParallelotope` type represents parallelotopes in constraint form.

The constraint form is described next.
Let ``D ∈ \\mathbb{R}^{n × n}`` be a matrix and let ``c ∈ \\mathbb{R}^{2n}`` be
a vector. The parallelotope ``P ⊂ \\mathbb{R}^n`` generated by the directions
matrix ``D`` and the offset vector ``c`` is given by the set of points
``x ∈ \\mathbb{R}^{n}`` such that:

```math
    D_i ⋅ x ≤ c_{i},\\text{  and  } -D_i ⋅ x ≤ c_{n+i}
```
for ``i = 1, …, n``. Here ``D_i`` represents the ``i``-th row of ``D`` and ``c_i`` the ``i``-th
component of ``c``.

For details on the notions given in these notes as well as applications of parallelotopes in
reachability analysis we refer to [1] and [2]. For conversions between set representations
we refer to [3].

### References

[1] Tommaso Dreossi, Thao Dang, and Carla Piazza. *Reachability computation for polynomial dynamical systems.*
    Formal Methods in System Design 50.1 (2017): 1-38.

[2] Tommaso Dreossi, Thao Dang, and Carla Piazza. *Parallelotope bundles for polynomial reachability.*
    Proceedings of the 19th International Conference on Hybrid Systems: Computation and Control. ACM, 2016.

[3] Matthias Althoff, Olaf Stursberg, and Martin Buss. *Computing reachable sets of hybrid systems using
    a combination of zonotopes and polytopes.* Nonlinear analysis: hybrid systems 4.2 (2010): 233-249.
"""
struct HParallelotope{N<:Real, VN<:AbstractVector{N}, MN<:AbstractMatrix{N}} <: AbstractZonotope{N}
    directions::MN
    offset::VN

    # default constructor with dimension check
    function HParallelotope(D::MN, c::VN) where {N<:Real, VN<:AbstractVector{N}, MN<:AbstractMatrix{N}}
        @assert length(c) == 2*checksquare(D) "the length of the offset direction should be twice the size " *
            "of the directions matrix, but they are $(length(c)) and $(size(D)) dimensional respectively"
        return new{N, VN, MN}(D, c)
    end
end

# =================
# Getter functions
# =================

"""
    directions(P::HParallelotope{N}) where {N<:Real}

Return the directions matrix of a parallelotope.

### Input

- `P` -- parallelotope in constraint representation

### Output

A matrix where each row represents a direction of the parallelotope.
The negated directions `-D_i` are implicit (see [`HParallelotope`](@ref) for details).
"""
function directions(P::HParallelotope{N}) where {N<:Real}
    return P.directions
end

"""
    offset(P::HParallelotope{N}) where {N<:Real}

Return the offsets of a parallelotope.

### Input

- `P` -- parallelotope in constraint representation

### Output

A vector with the ``2n`` offsets of the parallelotope,
if ``n`` is the dimension of ``P``.
"""
function offset(P::HParallelotope{N}) where {N<:Real}
    return P.offset
end

# ========================================
# Functions required by the set interface
# ========================================

"""
    dim(P::HParallelotope{N}) where {N<:Real}

Return the dimension of a parallelotope.

### Input

- `P` -- parallelotope in constraint representation

### Output

An integer representing the dimension of the parallelotope
"""
function dim(P::HParallelotope{N}) where {N<:Real}
    return size(P.directions, 1)
end

"""
    base_vertex(P::HParallelotope{N}) where {N<:Real}

Compute the base vertex of the given parallelotope in constraint representation.

### Input

- `P` -- parallelotope in constraint representation

### Output

The base vertex of ``P``.

### Algorithm

Intuitively, the base vertex is the point on which the generators are anchored.
The base vertex can be computed as the solution of the ``n``-dimensional linear
system ``D_i x = c_{n+i}`` for ``i = 1, \\ldots, n``, see [1, Section 3.2.1].

[1] Dreossi, Tommaso, Thao Dang, and Carla Piazza. *Reachability computation for
    polynomial dynamical systems.* Formal Methods in System Design 50.1 (2017): 1-38.
"""
function base_vertex(P::HParallelotope{N}) where {N<:Real}
    D, c = P.directions, P.offset
    n = dim(P)
    v = to_negative_vector(c[n+1:end]) # converts to a dense vector as well
    return D \ v
end

"""
    extremal_vertices(P::HParallelotope{N}) where {N<:Real}

Compute the extremal vertices with respect to the base vertex of the
given parallelotope in constraint representation.

### Input

- `P` -- parallelotope in constraint representation

### Output

The list of vertices connected to the base vertex of ``P``.

### Algorithm

Let ``P`` be a parallelotope in constraint representation with directions
matrix ``D`` and offset vector ``c``. We denote the *extremal vertices* of ``P``
with respect to its base vertex ``q`` to be those vertices of ``P`` which have
an edge in common with ``q``.  The extremal vertices can be computed as the
solution of the ``n``-dimensional linear systems of equations ``D x = v_i``
where for each ``i = 1, \\ldots, n``,
``v_i = [-c_{n+1}, \\ldots, c_i, \\ldots, -c_{2n}]``.

We refer to [1, Section 3.2.1] for details.

[1] Tommaso Dreossi, Thao Dang, and Carla Piazza. *Reachability computation for
    polynomial dynamical systems.* Formal Methods in System Design 50.1 (2017): 1-38.
"""
function extremal_vertices(P::HParallelotope{N}) where {N<:Real}
    D, c = P.directions, P.offset
    n = dim(P)
    v = to_negative_vector(c[n+1:end])
    vertices = Vector{Vector{N}}(undef, n)
    @inbounds for i in 1:n
        h = copy(v)
        h[i] = c[i]
        vertices[i] = D \ h
    end
    return vertices
end

"""
    center(P::HParallelotope{N}) where {N<:Real}

Return the center of a parallelotope.

### Input

- `P` -- parallelotope in constraint representation

### Output

The center of the parallelotope.

### Algorithm

Let ``P`` be a parallelotope with base vertex ``q`` and list of extremal
vertices with respect to ``q`` given by the set ``\\{v_i\\}`` for
``i = 1, \\ldots, n``. Then the center is located at

```math
    c = q + \\sum_{i=1}^n \\frac{v_i - q}{2} = q (1 - \\frac{n}{2}) + \\frac{s}{2},
```
where ``s := \\sum_{i=1}^n v_i`` is the sum of extremal vertices.
"""
function center(P::HParallelotope{N}) where {N<:Real}
    n = dim(P)
    q = base_vertex(P)
    E = extremal_vertices(P)
    s = sum(E)
    return q * (1 - n/2) + s/2
end

"""
    genmat(P::HParallelotope{N}) where {N<:Real}

Return the generator matrix of a parallelotope.

### Input

- `P` -- parallelotope in constraint representation

### Output

A matrix where each column represents one generator of the parallelotope `P`.

### Algorithm

Let ``P`` be a parallelotope with base vertex ``q`` and list of extremal
vertices with respect to ``q`` given by the set ``\\{v_i\\}`` for
``i = 1, \\ldots, n``. Then, the ``i``-th generator of ``P``, represented as the
``i``-th column vector ``G[:, i]``, is given by:

```math
    G[:, i] = \\frac{v_i - q}{2}
```
for ``i = 1, \\ldots, n``.
"""
function genmat(P::HParallelotope{N}) where {N<:Real}
    E = extremal_vertices(P)
    q = base_vertex(P)
    return 1/2 * hcat(E...) .- q/2
end

"""
    generators(P::HParallelotope{N}) where {N<:Real}

Return an iterator over the generators of a parallelotope.

### Input

- `P` -- parallelotope in constraint representation

### Output

An iterator over the generators of `P`.
"""
function generators(P::HParallelotope{N}) where {N<:Real}
    return generators_fallback(P)
end

# ========================
# Type-specific functions
# ========================

"""
    constraints_list(P::HParallelotope{N}) where {N<:Real}

Return the list of constraints of the given parallelotope.

### Input

- `P` -- parallelotope in constraint representation

### Output

The list of constraints of `P`.
"""
function constraints_list(P::HParallelotope{N}) where {N<:Real}
    D, c = P.directions, P.offset
    n = dim(P)
    clist = Vector{LinearConstraint{N}}(undef, 2n)
    @inbounds for i in 1:n
        clist[i] = LinearConstraint(D[i, :], c[i])
        clist[i+n] = LinearConstraint(-D[i, :], c[i+n])
    end
    return clist
end
