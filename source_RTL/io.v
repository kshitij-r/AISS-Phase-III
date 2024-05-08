module IO (
   gpio_match, gpio_write, odata_write, odataand_write,
   odataorr_write, oen_write, idata_write, itype_write,
   ipol_write, imask_write, imaskand_write, imaskorr_write, ilat_write,
   ilatand_write, gpio_read, odataxor_write
   );
   inout gpio_match, gpio_write, odata_write, odataand_write;
   inout odataorr_write, oen_write, idata_write, itype_write;
   inout ipol_write, imask_write, imaskand_write, imaskorr_write;     	    inout gpio_read,   ilat_write, odataxor_write;
   inout ilatand_write;
endmodule
