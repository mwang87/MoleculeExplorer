class ClusterNode
    attr_accessor :index
    attr_accessor :mz
    attr_accessor :neighbors
    attr_accessor :identification

    def initialize(index, mz, identification)  
        # Instance variables  
        @index = index
        @mz = mz
        @neighbors = Array.new
        @identification = identification
    end

    def add_neighbor(neighbor_index)
        @neighbors.push(neighbor_index)
    end
end

class Network
    def initialize()
        @clusters = Hash.new
    end

    def add_node(node_index, mz, identification)
        node_object = ClusterNode.new(node_index, mz, identification)
        @clusters[node_index] = node_object
    end

    def add_edge(node_index_one, node_index_two)
        @clusters[node_index_one].add_neighbor(node_index_two)
        @clusters[node_index_two].add_neighbor(node_index_one)
    end

    def get_node_neighbors(node_index)
        return @clusters[node_index].neighbors
    end

    def get_node(node_index)
        return @clusters[node_index]
    end
end

