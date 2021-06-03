// NOT MINE
package zappos;

import java.util.ArrayList;

import org.json.simple.JSONObject;

public class XSumClosest {
  /**
   * find all the sets of gifts that 
   * total price matches the target value
   * 
   * @param plist the poll of the products for searching gift sets3
   * @param x number of gifts want to buy
   * @param target total price that the user specified at input
   * @return list of sets of the products
   */
  public ArrayList < ArrayList < JSONObject >> findSumClosest(ArrayList < JSONObject > plist, int x, double target) {
    int length = plist.size();
    double diff = Double.MAX_VALUE;
    int i, j, k, p;
    double tmpsum;
    double sum; // keep the sum of the prices that matches the target closest
    int start, end;
    ArrayList < ArrayList < JSONObject >> res = new ArrayList < ArrayList < JSONObject >> ();

    //if input #of gifts is greater than the collection
    if (x > length || x < 1) {
      System.out.println("Please give a item number between 1 and number of products found (" + length + ")");
      return res;
    }

    //if input #of gifts is equal the collection
    if (x == length)
      res.add(plist);

    sum = 0;
    //if input #of gifts is 1, then find the product matches the target closest
    if (x == 1) {
      for (i = 0; i < length; i++) {
        sum = getPrice(plist.get(i));
        if (Math.abs(sum - target) < Math.abs(diff)) {
          diff = sum - target;
          ArrayList < JSONObject > tmp = new ArrayList < JSONObject > ();
          tmp.add(plist.get(i));
          res.clear();
          res.add(tmp);
        } else if (Math.abs(sum - target) < Math.abs(diff)) {
          ArrayList < JSONObject > tmp = new ArrayList < JSONObject > ();
          tmp.add(plist.get(i));
          res.add(tmp);
        }
      }
    }
    //if input #of gifts is 2, then find 2 product matches the target closest
    // use two pointers to navigate from both ends through the list, O(n) time
    if (x == 2) {
      start = 0;
      end = length - 1;
      while (start < end) {
        sum = getPrice(plist.get(start)) + getPrice(plist.get(end));
        if (Math.abs(sum - target) < Math.abs(diff)) {
          diff = Math.abs(sum - target);
          sum = getPrice(plist.get(start)) + getPrice(plist.get(end));
          ArrayList < JSONObject > tmp = new ArrayList < JSONObject > ();
          tmp.add(plist.get(start));
          tmp.add(plist.get(end));
          res.clear();
          res.add(tmp);
          //System.out.println(k);
          //System.out.println(res);
        } else if (Math.abs(sum - target) == Math.abs(diff)) {
          diff = Math.abs(sum - target);
          ArrayList < JSONObject > tmp = new ArrayList < JSONObject > ();
          tmp.add(plist.get(start));
          tmp.add(plist.get(end));
          res.add(tmp);

        }
        if (sum <= target) {
          start++;
        } else {
          end--;
        }
      }
    }
    //if input #of gifts (x) is greater than 2, iterate through the first x-2 items, 
    //use the same method to find last 2 items and find total x items matches the target closest
    // e.g. if there are 5 items, the first x-2 items start as 0,1,2 and then next time 0,1,3

    if (x > 2) {
      int[] index = new int[x - 2]; //store the index of first x-2 items
      for (i = 0; i < index.length; i++)
        index[i] = i; //initially, select the first x-2 items as 0,1,2...in the product list

      for (j = x - 3; j >= 0; j--) {
        if (j == x - 3)
          k = index[j];
        else k = index[j] + 1; //after first run of search,
        // the start index for searching the one item ahead need plus 1

        while (k < (length - 2)) {
          index[j] = k;
          tmpsum = 0;
          p = j + 1;
          while (p < x - 2 && index[p - 1] < length - 2) {
            index[p] = index[p - 1] + 1;
            tmpsum += getPrice(plist.get(index[p]));
            p++;
          } // the index of items on the gift list should increase one by one
          // adding all x-2 of the item prices to the tmpsum;
          for (p = j; p >= 0; p--) {
            //System.out.println(index);
            tmpsum += getPrice(plist.get(index[p]));
          }
          //tmplist host temporary elements of the result
          ArrayList < JSONObject > tmplist = new ArrayList < JSONObject > ();
          for (p = 0; p < x - 2; p++)
            tmplist.add(plist.get(index[p]));

          start = index[x - 3] + 1; //first pointer start from front
          end = length - 1; //second pointer start from end
          sum = tmpsum + getPrice(plist.get(start)) + getPrice(plist.get(end));

          while (start < end) { //navigate two pointers until start and end meet or go over each other
            sum = tmpsum + getPrice(plist.get(start)) + getPrice(plist.get(end));
            if (Math.abs(sum - target) < Math.abs(diff)) {
              diff = Math.abs(sum - target);
              sum = tmpsum + getPrice(plist.get(start)) + getPrice(plist.get(end));
              ArrayList < JSONObject > tmp = new ArrayList < JSONObject > (tmplist);
              tmp.add(plist.get(start));
              tmp.add(plist.get(end));
              res.clear();
              res.add(tmp);
              //System.out.println(k);
              //System.out.println(res);
            } else if (Math.abs(sum - target) == Math.abs(diff)) {
              diff = Math.abs(sum - target);
              ArrayList < JSONObject > tmp = new ArrayList < JSONObject > (tmplist);
              tmp.add(plist.get(start));
              tmp.add(plist.get(end));
              res.add(tmp);

            }
            if (sum <= target) { //if sum is smaller, advance front pointer
              start++;
            } else {
              end--; //if sum is greater, advance end pointer
            }
          } //end-while
          k++;
        }

        //System.out.println(j);
        //System.out.println(res);
      }
    }
    return res;

  }

  /**
   * returns the price of a JSONObject
   * @param job the JSONObject passed in
   */

  public double getPrice(JSONObject job) {
    return Double.parseDouble(((String) job.get("price")).substring(1));
  }

}
