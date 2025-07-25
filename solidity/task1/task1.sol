
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting{
    // 存储候选人的得票数，键为候选人名称，值为得票数
    mapping(string => uint256) private votes;

    //候选人列表
    string[] private candidates;

    //允许用户投票给某个候选人
    function vote(string memory candidate) public {
         //新增候选人
         if(votes[candidate] == 0) {
            candidates.push(candidate);
         }
         votes[candidate] += 1;
    } 

    //返回某个候选人的得票数
    function getVotes(string memory candidate) public view returns(uint256 count){
         return votes[candidate];
    }

    //重置所有候选人的得票数
    function resetVotes() public  {
        for (uint i=0; i <candidates.length;i++) {
            string memory candidate = candidates[i];
            delete votes[candidate];
        }
        delete candidates;
    }

    //反转字符串
    function reverseString(string memory input) public pure returns(string memory output) {
        bytes memory inputBytes = bytes(input);
        uint len = inputBytes.length;
        bytes memory outputBytes = new bytes(len);
        for (uint i=0;i<len;i++) {
           outputBytes[i] = inputBytes[len-1-i];
        }
        return string(outputBytes);
    }

     // 定义数值和对应罗马字符
    uint16[13] private values = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1];
    string[13] private symbols = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"];

     // 整数转罗马数字
    function intToRoman(uint256 num) public view returns (string memory) {
        // 验证输入范围（1-3999）
        require(num > 0 && num < 4000, "Input must be between 1 and 3999");
        
        // 存储结果的字节数组
        bytes memory result = new bytes(32);
        uint256 resultIndex = 0;
        
        // 遍历所有符号
        for (uint256 i = 0; i < values.length; i++) {
            // 当当前值小于等于剩余数字时
            while (num >= values[i]) {
                // 获取当前符号的字节表示
                bytes memory symbolBytes = bytes(symbols[i]);
                
                // 将符号复制到结果中
                for (uint256 j = 0; j < symbolBytes.length; j++) {
                    if (resultIndex >= result.length) {
                        // 动态扩展结果数组大小
                        bytes memory newResult = new bytes(result.length + 32);
                        for (uint256 k = 0; k < result.length; k++) {
                            newResult[k] = result[k];
                        }
                        result = newResult;
                    }
                    result[resultIndex++] = symbolBytes[j];
                }
                
                // 减去已处理的值
                num -= values[i];
            }
        }
        
        // 将字节数组转换为字符串并返回
        bytes memory finalResult = new bytes(resultIndex);
        for (uint256 i = 0; i < resultIndex; i++) {
            finalResult[i] = result[i];
        }
        return string(finalResult);
    }

    mapping(bytes1 => uint256) private symbolToValues;

    function romanToInt(string memory s) public  returns(uint256){
             //初始化字符到数值的映射
             symbolToValues['I']=1;
             symbolToValues['V']=5;
             symbolToValues['X']=10;
             symbolToValues['L']=50;
             symbolToValues['C']=100;
             symbolToValues['D']=500;
             symbolToValues['M']=1000;
             
             bytes memory roman = bytes(s);
             uint256 n = roman.length;
             uint256 total = 0;
             // 遍历每个字符
             for (uint256 i=0;i<n;i++) {
                // 获取当前字符的值
                uint256  current = symbolToValues[roman[i]];
                require(current != 0, "Invalid Roman numeral");

                if(i<n-1) {
                    uint256  next = symbolToValues[roman[i+1]];
                    require(next != 0,"Invalid Roman numeral");
                    // 检查是否需要特殊处理（减法规则）
                    if(current <next) {
                      total -= current;
                      continue;
                    }
                }
                 // 正常情况：加上当前值
                total += current;    
             }
            return total;
    }

    //合并两个有序数组 (Merge Sorted Array),要求均为升序
    function mergeSortedArray(uint[] memory arrA,uint[] memory arrB) 
       public pure returns(uint[] memory) {
        if (arrA.length == 0) return arrB;
        if (arrB.length == 0) return arrA;
        uint lenA = arrA.length;
        uint lenB = arrB.length;
        uint[] memory merageArray = new uint[](lenA + lenB);

        uint i=0;// arrA 指针
        uint j=0;// arrB 指针
        uint k=0;// merged 指针
        while(i<lenA && j<lenB) {
            if(arrA[i]<arrB[j]) {
               merageArray[k] = arrA[i];
               i++;
            } else {
                merageArray[k] = arrB[j];
                j++;
            }
            k++;
        }

        while(i<lenA) {
            merageArray[k] = arrA[i];
            i++;
            k++;
        }

        while(j<lenB) {
            merageArray[k] = arrB[j];
            j++;
            k++;
        }
        return merageArray;
    }

    //二分查找 (Binary Search)
    function binarySearch(uint[] memory array,uint target) public pure returns(int) {
        if(array.length == 0) return -1;

        uint left = 0;
        uint right = array.length - 1;
        while(left <= right) {
           uint mid = left + (right - left)/2;
           if(array[mid] == target) {
                return int(mid);
           } else if(array[mid]<target) {
                left = mid + 1;
           } else {
                right = mid - 1;
           }
        }
        return -1;
    }

}