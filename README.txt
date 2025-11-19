Cài extention: LateX Workshop của james Yu
Chạy bằng lệnh: latexmk -xelatex main.tex
Lệnh này tự động update khi save: latexmk -xelatex -pvc main.tex


QUY TRÌNH PULL CODE:
Clone code từ github
git clone https://github.com/VODUYTAN16/CT204.git
cd CT204

Kiểm tra branch hiện tại:
# git branch
checkout qua branch dự án latex
# git checkout latex_CT204
tạo branch mới từ branch hiện tại
# git checkout -b <tên branch mới>

CHỈ LÀM VIỆC TRÊN BRANCH MỚI VÀ ĐẨY CODE LÊN BRANCH MỚI
TRƯỚC KHI LÀM VIỆC PHẢI THỰC HIỆN PULL CODE MỚI NHẤT TỪ GITHUB VỀ MÁY
git fetch
git rebase origin/latex_CT204
(xử lý conflict nếu có và gõ lệnh theo từng bước có trên terminal)


Commit và đưa code lên nhánh mới của mình
Lên github tạo yêu cầu pull request và để mn xem xét trước khi merge thật sự vào branch chính latex_CT204



