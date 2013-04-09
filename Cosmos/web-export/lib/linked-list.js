var linkedListNode = function(key){
    return {
        key: key,
        next: null
    };
};

var linkedList = function(){
    var head = null;
    var size = 0;
    
    // prepend
    var insert = function(node){
        node.next = head;
        head = node;
        size += 1;
    };
    
    // append
    var add = function(node){
        size += 1;
        
        if (head == null){
            node.next = head;
            head = node;
            return;
        }
        
        curr = head;
        while (curr.next != null){
            curr = curr.next;
        }
        curr.next = node;
    }

    var search = function(key){
        var node = head;
        while (node !== null && node.key !== key){
            node = node.next;
        };
        return node;
    };

    var del = function(node){        
        size -= 1;
        
        if (node === head){
            head = node.next;
            return;
        }

        var prev = head;
        while (prev.next !== null && prev.next !== node){
            prev = prev.next;
        };
        
        if (prev !== null){
            if (prev.next == null){
                 size += 1;
            }
            prev.next = node.next;
        }
    };

    var getHead = function(){
        return head;
    };
    
    var getSize = function(){
        return size;
    };
    
    var get = function(n){
        var node = head;
        while (node !== null && n != 0){
            node = node.next;
            n -= 1;
        };
        return node;
    }

    return {
        insert: insert,
        add: add,
        del: del,
        search: search,
        getHead: getHead,
        getSize: getSize,
        get: get
    };
};
