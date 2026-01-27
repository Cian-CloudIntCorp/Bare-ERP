#include <iostream>
#include <rte_eal.h>
#include <rte_ethdev.h>

int main(int argc, char **argv) {
    // Initialize the DPDK Environment Abstraction Layer (EAL)
    int ret = rte_eal_init(argc, argv);
    if (ret < 0) {
        std::cerr << "Error: Cannot initialize EAL." << std::endl;
        return 1;
    }

    std::cout << "DPDK EAL initialized successfully." << std::endl;

    // Basic check for available network devices
    uint16_t nb_ports = rte_eth_dev_count_avail();
    if (nb_ports == 0) {
        std::cerr << "Error: No network ports available." << std::endl;
        rte_eal_cleanup();
        return 1;
    }

    std::cout << "Found " << nb_ports << " available network ports." << std::endl;

    // TODO: Add logic here to initialize and configure network devices (ports)
    // For now, we just ensure EAL initialization and port detection works.

    // Clean up DPDK resources
    rte_eal_cleanup();

    return 0;
}