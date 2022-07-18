.eqv SEVENSEG_LEFT    0xFFFF0011 	# Dia chi cua den led 7 doan trai	
					#Bit 0 = doan a         
					#Bit 1 = doan b	
					#Bit 7 = dau . 
.eqv SEVENSEG_RIGHT   0xFFFF0010 	# Dia chi cua den led 7 doan phai 
.eqv IN_ADRESS_HEXA_KEYBOARD       0xFFFF0012  
.eqv OUT_ADRESS_HEXA_KEYBOARD      0xFFFF0014	
.eqv KEY_CODE   0xFFFF0004         	# ASCII code from keyboard, 1 byte 
.eqv KEY_READY  0xFFFF0000        	# =1 if has a new keycode ?   (t1 = 1 tuc la co ky tu nhap vao tu ban phim)                               
				        # Auto clear after lw  
.eqv DISPLAY_CODE   0xFFFF000C   	# ASCII code to show, 1 byte 
.eqv DISPLAY_READY  0xFFFF0008   	# =1 if the display has already to do  
	                                # Auto clear after sw  
.eqv MASK_CAUSE_KEYBOARD   0x0000034     # Keyboard Cause  
					# bien de xac dinh loi nhap vao la do nguoi dung nhap mot ky tu nao do tu ban phim
					# dung de so sanh voi Coproc0.$13(cause)  
					# neu Coproc0.$13(cause) = 0x0000034 thi viec ngat xay ra khi nguoi dung nhap ki tu nao do de ngat chu khong phai la loi vi nguyen nhan khac
  
.data 
bytehex     : .byte 63,6,91,79,102,109,125,7,127,111 			# danh sach luu gia tri cua tung chu so den LED
									# dung de dua vao 7 SEG hien thi ra cac so tu 0 -> 9
storestring : .space 1000						#khoang trong de luu cac ky tu nhap tu ban phim.
stringsource : .asciiz "Bo mon ky thuat may tinh" 
Message: .asciiz "\n So ky tu trong 1s :  "
numkeyright: .asciiz  "\n So ky tu nhap dung la: "  
notification: .asciiz "\n ban co muon quay lai chuong trinh? "
typingtime: .asciiz  "\n Thoi gian nhap la: "
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
# MAIN Procsciiz ciiz edure 
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
.text
	li   $k0,  KEY_CODE              
	li   $k1,  KEY_READY                    
	li   $s0, DISPLAY_CODE              
	li   $s1, DISPLAY_READY 
	li $s7, 0			# de luu thoi gian nhap cua nguoi dung
MAIN:         
	li $s4,0 			# dung de dem toan bo so ky tu nhap vao (lengthOf(storestring))
  	li $s3,0			# dung de dem so vong lap 
 	li $t4,10			# dung de lam so bi chia trong label DISPLAY_DIGITAL
  	li $t5,200			# luu gia tri so vong lap. 
	li $t6,0			# bien dem so ky tu nhap duoc trong 1s
	li $t9,0			# bien check label PRINT
					# neu label PRINT duoc chay thi t9 = 1
					# neu label PRINT chua chay thi t9 = 0
	
LOOP:          
WAIT_FOR_KEY:  
 	lw   	$t1, 0($k1)                  	# $t1 = [$k1] = KEY_READY              
	beq  	$t1, $zero,ONE_SECOND_CHECK               	# if $t1 == 0 then Polling ( neu t1 ==0 thi tuc la chua co ky tu nhap vao -> XXX
								      #neu t1 == 1 thi tuc la co ky tu nhap vao -> MAKE_INTER      
MAKE_INTER:
	addi 	$t6,$t6,1    		  	#tang bien dem ky tu nhap duoc trong 1s len 1 ( t6 dung de dem ky tu nhap vao trong 1s
	teqi 	$t1, 1                       	# if $t1 = 1 then raise an Interrupt  (t1 = KEY_READY)
						# teqi dung trong truong hop muon xu ly ngat mem (Ngat do nhap tu ban phim)
						# Lam tuong tu HOME ASSIGNMENT 5 trong LAB 11
#---------------------------------------------------------         
# Loop an print sequence numbers         
#---------------------------------------------------------
ONE_SECOND_CHECK:          
	#neu da lap dk 200 vong se nhay den xu ly so ky tu nhap trong 1s.
	addi    $s3, $s3, 1      	# dem so lan lap 1s. ($s3 se la so vong lap 1s da lap qua tu khi chay chuong trinh)
	div 	$s3,$t5			# lay so vong lap chia cho 200 de xac dinh da duoc 1s hay chua 
	mfhi 	$t7			# luu phan du cua phep chia tren (t7 bang phan du cua phep chia $s3/$t5)
	bne 	$t7,0,SLEEP		# neu chua duoc 1s nhay den label SLEEP
					# neu da duoc 1s thi nhay den nhan SETCOUNT de thuc hien in ra man hinh

# IN RA MAN HINH CCONSOLE "so ki tu nhap duoc trong 1s: $t6"
SETCOUNT:
	li 	$s3,0			# tai lap gia tri cua $s3 ve 0 de dem lai so vong lap cho cac lan tiep theo
	li 	$v0,4			# bat dau chuoi lenh in ra console so ky tu nhap duoc trong 1s 
					# (v0 = 4: print string)
	la 	$a0,Message			# in ra Message: "\n So ky tu trong 1s :  "
	syscall	
	li    	$v0,1            	#in ra so ky tu trong 1s
					# v0 = 1: in ra interger
	add   	$a0,$t6,$zero    	# in ra so $t6 = so ky tu nhap vao trong 1s
	syscall
	
	addi	$s7, $s7, 1		# sau moi 1s thi cong bien dem thoi gian nhap vao len 1 don vi 

# HIEN THI LED KHI VONG LAP DANG LAP, GIA TRI CUA LED LA SO KI TU NHAP VAO TRONG 1s KHI VONG LAP DANG CHAY
DISPLAY_DIGITAL: 
	div 	$t6,$t4			# lay so ky tu nhap duoc trong 1s chia cho 10 
					# neu lon hon 10 thi se phai in ra hang chuc led 7 thanh ben trai
					# nen can chia cho 10 de xem so ki tu nhap vao trong 1s co lon hon 10 hay khong
	mflo 	$t7			#luu gia tri phan nguyen, gia tri nay se duoc luu o den LED ben trai 
					# den led phia ben trai hien thi hang chuc cua so ki tu nhap vao nen se la phan nguyen khi chia cho 10
	la 	$s2,bytehex			# lay dia chi cua danh sach luu gia tri cua tung chu so den LED
	add 	$s2,$s2,$t7			# xac dinh dia chi cua gia tri  
					# (cong s2 voi t7 de laydia chi byte hex hien thi den led phia ben trai cho hang chuc neu so ki tu nhap vao >=10
					# neu so ki tu nhap vao trong 1s < 10 thi s2 khong doi va dua chinh gia tri s2 và 7SEG
	lb 	$a0,0($s2)                 	#lay noi dung cho vao $a0    (lay gia tri cua byte_hex dua va $a0)       
	jal   	SHOW_7SEG_LEFT       	# ngay den label den LED trai  (hien thi led theo gia tri $a0)
#------------------------------------------------------------------------
	mfhi 	$t7			#luu gia tri phan du cua phep chia, gia tri nay se duoc in ra trong den LED ben phai
					# phan du cua phep chia chinh la hang don vi cua so ki tu nhap vao trong 1s
	la 	$s2,bytehex			# lay dia chi byte_hex
	add 	$s2,$s2,$t7			# cong dia chi byte_hex voi gia tri du tuong ung de lay ra gia tri hexa tuong ung voi hang don vi
	lb 	$a0,0($s2)                	# lay ra gia tri hexa luu trong byte_hex tuong ung           
	jal  	SHOW_7SEG_RIGHT      	# show    
#------------------------------------------------------------------------                                            
	li    	$t6,0			#sau khi da hoan thanh dua bien dem so ky tu nhap duoc trong 1s ve 0 de bat dau cho chu ky moi
	beq 	$t9,1,ASK_LOOP		# t9 la bien check xem label PRINT da chay hay chua
					# neu label PRINT da duoc chay thi t9 =1
					# neu label PRINT chua duoc chay thi t9 = 0
					
					# tuc la can kiem tra neu t9 da duoc chạy thi viec CHECK_STRING da thuc hien xong (hoan thanh chuong trinh), 
					# chi quay lai DISPLAY_DIGITAL de hien thi ket qua len 7 SEG
					# nen chạy den ASK_LOOP de hoi nguoi dung co muon chay lai chuong trinh mot lan nua khong
	
SLEEP:  
	addi    $v0,$zero,32                   
	li      $a0,5              	# sleep 5 ms  ($a0 = the length of time to sleep in milliseconds)    
	syscall         
	nop           	          	# WARNING: nop is mandatory here. 
					# Giữa 2 lệnh syscall và lệnh jump, branch cần bổ sung thêm lệnh nop. Nếu không việc ghi nhận giá trị của thanh ghi PC vào EPC sẽ bị sai         
	b       LOOP          	 	# Loop (nhay nguoc lai ve LOOP de thuc hien tien trinh nhap vao)
	
END_MAIN: 
	li $v0,10			# exit
	syscall
	
SHOW_7SEG_LEFT:  
	li   $t0,  SEVENSEG_LEFT 	# assign port's address                   
	sb   $a0,  0($t0)        	# assign new value                    
	jr   $ra 
	
SHOW_7SEG_RIGHT: 
	li   $t0,  SEVENSEG_RIGHT 	# assign port's address                  
	sb   $a0,  0($t0)         	# assign new value                   
	jr   $ra 
	
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# PHAN PHUC VU NGAT
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
.ktext    0x80000180         		#chuong trinh con chay sau khi interupt duoc goi. (tu dong nhay den 0x80000180)       
	mfc0  $t1, $13                  # set $t1 to the value store in Coproc 0 register $13 (nguyen nhan ngat)
					# cho biet nguyên nhân làm tham chieu dia chi bo nho khong hop
					# thanh ghi $13 (cause) sẽ thay đổi các bit 2~6 cho biết nguyen nhân gây ra ngắt
	li    $t2, MASK_CAUSE_KEYBOARD              
	and   $at, $t1,$t2              # neu $t1 = $t2 thi sau khi AND $at = $t1 = $t2
	beq   $at,$t2, COUNTER_KEYBOARD              # tuc la neu nguyen nhan gay ra loi ($t1) = MASK_CAUSE_KEYBOARD thi nhay den COUNTER_KEYBOARD
	j    END_PROCESS  				# neu nguyen nhan gay ra loi khong phai la MASKE_CAUSE_KEYBOARD
							# thi nhay den END_PROCESS de tro ve chuong trinh chinh (ket thuc chuong trinh xu ly ngat)

# Kiem tra cac ky tu nhap vao, neu khong phai la ENTER thi chay tiep ki tu tiep theo, neu la ENTER thi nhay den END de ngat
COUNTER_KEYBOARD: 
READ_KEY:  lb   $t0, 0($k0)            	# $t0 = [$k0] = KEY_CODE : doc ky tu nhap vao
WAIT_FOR_DIS: 
	     lw   $t2, 0($s1)            	# $t2 = [$s1] = DISPLAY_READY            
	     beq  $t2, $zero, WAIT_FOR_DIS	# if $t2 == 0 then Polling                             
SHOW_KEY: 
	     sb $t0, 0($s0)              	# hien thi ky tu vua nhap tu ban phim tren man hinh MMIO
             la  $t7,storestring		# lay $t7 lam dia chi co so cua chuoi nhap vao
             add $t7,$t7,$s4			# $s4 la do dai xau nhap vao tu ban phim
             					# thay doi dia chi $t7 = baseStroreString(address) + lengthOf(storeString)
             sb $t0,0($t7)			# dua READ_KEY (bien doc duoc tu MMIO) vao vi tri tuong ung trong storestring
             addi $s4,$s4,1			# cong do dai xau storeString len 1 vi da them vao 1 ki tu
             beq $t0,10,END                    	# NEU PHIM NHAP VAO LA ENTER THI GOI DEN XU LY NGAT VA NHAY DEN END DE XU LY VIEC DEM CAC KY TU DUNG VA IN RA DIGITAL LAB SIM
END_PROCESS:   
                      
# Tro ve chuong trinh chinh sau khi xu ly xong Exception (ngat)
NEXT_PC:   mfc0    $at, $14	        # $at <= Coproc0.$14 = Coproc0.epc (lay gia tri thanh ghi $14(epc) ra luu vao $at 
	    addi    $at, $at, 4	        # $at = $at + 4 (next instruction) (cong $at len 4 don vi)
            mtc0    $at, $14	       	# Coproc0.$14 = Coproc0.epc <= $at  (luu $at nguoc lai vao $14 (epc))
            #mfc0 (để đọc thanh ghi trong bộ đồng xử lý C0) và mtc0 (để ghi giá trị vào thanh ghi trong bộ đồng xử lý C0)
RETURN:   eret                       	# tro ve len ke tiep cua chuong trinh chinh
					# $14 (epc) sẽ chứa địa chỉ kế tiếp của chương trình chính, để quay trở về sau khi xử lý các đoạn mã Exception xong. (giống như thanh ghi $ra)

#-------------------------------------------------------------------------------------------------
##################################################################################################
#-------------------------------------------------------------------------------------------------
#Tien xu ly truoc khi so sanh chuoi
END:
	li $v0,11         		# v0 = 11 : print character
	li $a0,'\n'         		#in xuong dong
	syscall 
	li $t1,0 			# $t1 de dem so ky tu da duoc xet
	li $t3,0                        # $t3 de dem so ky tu nhap dung
	li $t8,24			# luu $t8 la do dai xau da luu tru trong ma nguon. lengthOf(sourcestring)
					# t8 = lengthOf(sourceString)
					# s4 = lengthOf(storeString)
	slt $t7,$s4,$t8			# so sanh xem do dai xau nhap tu ban phim va do dai cua xau co dinh trong ma nguon
					#xau nao nho hon thi duyet theo do dai cua xau do
					# s4 la do dai xau nhap vao tu ban phim
	bne $t7,1, CHECK_STRING		# neu do dai sourcestring < storestring thi nhay den CHECK_STRING
	add $t8,$0,$s4			# neu sourcestring > storestring thi set lengthOf(sourcestring) = lengthOf(storestring)
	addi $t8,$t8,-1			#tru 1 vi ky tu cuoi cung la dau enter thi khong can xet.
					# chi can xet cac ki tu chu de tim ra cac ky tu dung, ky tu ENTER dung de ngat chuong trinh nen khong can xet

#------------------------------------------------------------------
# PHAN KIEM TRA CHINH TA
#------------------------------------------------------------------
CHECK_STRING:		
	la $t2,storestring		# lay dia chi co so cua chuoi nhap vao
	add $t2,$t2,$t1			# cong dia chi t2 voi t1 de ra dia chi ki tu thu t1 cua chuoi storestring
	li $v0,11			# in ra cac ky tu da nhap tu ban phim. (v0 =11 : print character)
	lb $t5,0($t2)			# lay ky tu thu $t1 trong storestring luu vao $t5 de so sanh voi ky tu thu $t1 o stringsource
	move $a0,$t5			# set a0 to contents ò t5
	syscall 
	la $t4,stringsource		# lay dia chi cua chuoi goc	
	add $t4,$t4,$t1			# cong dia chi t4 voi t1 de ra dia chi ki tu chu t1 cua chuoi sourcestring
	lb $t6,0($t4)			# lay ky tu thu $t1 trong stringsource luu vao $t6
	# So sanh ki tu thu t1 trong 2 chuoi storestring va sourcestring
	bne $t6,$t5,CONTINUE		# neu 2 ky tu thu $t1 giong nhau thi tang bien dem so ky tu dung len 1
					# neu 2 ky tu khong giong nhau thi nhay den CONTINUE de index+1 de so sanh cap ki tu tiep theo
	addi $t3,$t3,1			# Tang bien dem gia tri giong nhau len 1 (T3 LUU SO CAC KY TU GIONG NHAU HAY KI TU NHAP DUNG)
	
CONTINUE: 
	addi $t1,$t1,1			# sau khi so sanh 1 ky tu, tang bien dem len 
	beq $t1,$t8,PRINT		# kiem tra da duyet het chuoi chua
					# neu da duyet het so ky tu can xet thi in ra man hinh so ky tu nhap dung
	j CHECK_STRING			# con khong thi tiep tuc xet tiep cac ky tu 

# IN KET QUA
PRINT:	li $v0,4			# v0 = 4: print string
	la $a0,numkeyright		# in ra chuoi "\n So ky tu nhap dung la: "   
	syscall
	li $v0,1			# v0 = 1: print interger
	add $a0,$0,$t3			# luu so ky tu nhap dung vao a0 de in ra man hinh
	syscall
	li $t9,1			# set bien t9 =1 (the hien cho viec da chay ham PRINT roi)
	li $t6,0			# sau khi ket thuc chuong trinh, so ky tu dung duoc luu vao $t6 roi quay tro ve phan hien thi.
	li $t4,10			# thanh ghi $t4 gan tro lai gia tri 10 
					# vi o lenh tren da dung $t4 luu gia tri dia chi cua source code
	add $t6,$0,$t3			# t6 = t3 = so ky tu nhap dung
	
	
	# IN THOI GIAN NHAP
	li $v0, 4			# in ra string "Thoi gian nhap la: "
	la $a0, typingtime
	syscall
	
	li $v0, 1
	add $a0, $0, $s7		# $s7 la thoi gian nhap
	syscall
	
	li $v0, 11			# in ra ky tu 's' (giay)
	li $a0, 's'
	syscall
	
	# reset thoi gian nguoi dung nhap vao
	li $s7,0

	# Hien thi ket qua len led 7 thanh
	b DISPLAY_DIGITAL 

# HIEN THI CONFIRM DIALOG
ASK_LOOP: 				
	li $v0, 50			# Hien thi confirm dialog
	la $a0, notification		# "\n ban co muon quay lai chuong trinh? "
	syscall
	beq $a0,0,MAIN			# Neu chon YES thi a0 = 0 tuc la nguoi dung muon chay lai chuong trinh
					# option
					# 0: Yes
					# 1: No
					# 2: Cancel		
	b EXIT				# neu nguoi dung khong muon chay lai chuong trinh thi exit
EXIT: ...
