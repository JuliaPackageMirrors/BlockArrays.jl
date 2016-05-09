
"""
A `BlockIndex` is an index which stores a global index in two parts: the block
and the offset index into the block.
"""
immutable BlockIndex{N}
    I::NTuple{N, Int}
    α::NTuple{N, Int}
end

@propagate_inbounds function Base.getindex{T,N}(block_array::BlockArray{T, N}, block_index::BlockIndex)
    return getblock(block_array, block_index.I...)[block_index.α...]
end

@propagate_inbounds function Base.setindex!{T,N}(block_array::BlockArray{T, N}, v, block_index::BlockIndex)
    getblock(block_array, block_index.I...)[block_index.α...] = v
end


@inline function _find_block(block_sizes, dim::Int, i::Int)
    accum = 0
    block = 0
    while accum < i
        block += 1
        accum += block_sizes[dim][block]
    end
    accum -= block_sizes[dim][block]
    return block, i - accum
end

"""
Converts from a global index to a `BlockIndex`.
"""
function global2blockindex{N}(block_sizes::NTuple{N, Vector{Int}}, i::NTuple{N, Int})
    block_index = ntuple(k->_find_block(block_sizes, k, i[k]), Val{N})
    I = ntuple(k->block_index[k][1], Val{N})
    α = ntuple(k->block_index[k][2], Val{N})
    return BlockIndex(I, α)
end

"""
Converts from a `BlockIndex` to a global index.
"""
function blockindex2global{N}(block_sizes::NTuple{N, Vector{Int}}, block_index::BlockIndex{N})
    ntuple(k-> _sumiter(block_sizes[k], block_index.I[k]-1) + block_index.α[k], Val{N})
end