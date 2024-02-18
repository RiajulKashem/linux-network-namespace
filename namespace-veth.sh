#Create Network Namespaces
sudo ip netns add ns1
sudo ip netns add ns2

# By default, network interfaces of created netns are down, even loop interfaces. make them up.
sudo ip netns exec ns1 ip link set lo up
sudo ip netns exec ns1 ip link

sudo ip netns exec ns2 ip link set lo up
sudo ip netns exec ns2 ip link

# create veth pair cable
sudo ip link add veth0 type veth peer name veth1

# Attach cable to the namepsaces
sudo ip link set veth0 netns ns1
sudo ip link set veth1 netns ns2

# By Default interfaces are down let's up them
sudo ip netns exec ns1 ip link set veth0 up
sudo ip netns exec ns2 ip link set veth1 up

# Assign IP Addresses for the namespaces
sudo ip netns exec ns1 ip addr add 10.0.1.1/24 dev veth0
sudo ip netns exec ns2 ip addr add 10.0.1.2/24 dev veth1

# Check namespace can communiate each other
sudo ip netns exec ns1 ping -c 2 10.0.1.2
sudo ip netns exec ns2 ping -c 2 10.0.1.1

#To delete the namespaces and veth interfaces
ip netns del ns1
ip netns del ns2
ip link del veth0
ip link del veth1

