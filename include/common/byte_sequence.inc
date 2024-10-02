ByteSequence struct
	data_size qword ?
	data qword ?
ByteSequence ends

externdef CreateBS: proc
externdef FreeBS: proc
externdef CompareBS: proc
externdef CopyBSData: proc