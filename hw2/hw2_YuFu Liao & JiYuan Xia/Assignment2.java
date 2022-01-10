/* start the simulation */

//YuFu Liao 10478967
//JiYuan Xia 10468319

import java.io.FileNotFoundException;
import java.io.PrintStream;

public class Assignment2 {
    public static void main(String[] args) {
        Thread thread = new Thread(new Bakery());
        thread.start();
        
//        try {
//			PrintStream out =new PrintStream("C:/Users/liaoy/OneDrive/Desktop/output.txt");
//			System.setOut(out);
//			
//		} catch (FileNotFoundException e1) {
//			// TODO Auto-generated catch block
//			e1.printStackTrace();
//		}

        try {
            thread.join();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
