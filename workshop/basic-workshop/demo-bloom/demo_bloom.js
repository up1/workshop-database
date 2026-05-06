// Demo bloom filter with nodejs
// check existing email in arrays
// 1. Initialize a Bit Array: Let’s assume our Bloom Filter uses a bit array of size 10, initially all set to 0
// 2. Define 2 hash functions: For simplicity, we will use two hash functions:
//    - Hash Function 1: hash1(email) = (sum of ASCII values of characters in email) % 10
//    - Hash Function 2: hash2(email) = (length of email) % 10
// 3. Add Emails to Bloom Filter: To add an email to the Bloom Filter, we will compute the hash values using both hash functions and set the corresponding bits in the bit array to 1.
//    - For example, if we want to add "test@example.com" to the Bloom Filter, we would compute hash1("test@example.com") and hash2("test@example.com") and set the corresponding bits in the bit array to 1.  
// 4. Check for Email Existence: To check if an email exists in the Bloom Filter, we will compute the hash values using both hash functions and check if the corresponding bits in the bit array are set to 1.
//    - For example, if we want to check if "test@example.com" exists in the Bloom Filter, we would compute hash1("test@example.com") and hash2("test@example.com") and check if the corresponding bits in the bit array are set to 1.

class BloomFilter {
    constructor(size) {
        this.size = size;
        this.bitArray = new Array(size).fill(0);
    }

    hash1(email) {
        return email.split('').reduce((sum, char) => sum + char.charCodeAt(0), 0) % this.size;
    }

    hash2(email) {
        return email.length % this.size;
    }

    add(email) {
        const index1 = this.hash1(email);
        const index2 = this.hash2(email);
        this.bitArray[index1] = 1;
        this.bitArray[index2] = 1;
    }

    check(email) {
        const index1 = this.hash1(email);
        const index2 = this.hash2(email);
        return this.bitArray[index1] === 1 && this.bitArray[index2] === 1;
    }
}

// Example usage
const bloomFilter = new BloomFilter(100);
bloomFilter.add("test@example.com");

console.log(bloomFilter.check("test@example.com")); // true
// NOTE: This returns true as a FALSE POSITIVE — a classic Bloom filter trait.
// "not_in_filter@example.com" hashes to bits (5, 5), which collide with the
// bits (5, 6) set by "test@example.com". Bloom filters can have false positives
// but never false negatives. Larger bit arrays + more hash functions reduce this.
console.log(bloomFilter.check("not_in_filter@example.com")); // true (false positive!)