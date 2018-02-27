REQUIRE_IMAGE_METADATA=1

platform_check_image() {
	return 0;
}

platform_pre_upgrade() {
	nand_do_upgrade "$1"
}

platform_nand_pre_upgrade() {
	CI_UBIPART="firmware1"
}
