import java.math.BigDecimal;
import java.sql.Date;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Random;
import java.util.concurrent.Semaphore;

public class Customer implements Runnable {
	private Bakery bakery;
	private Random rnd;
	private List<BreadType> shoppingCart;
	private int shopTime;
	private int checkoutTime;

	/**
	 * Initialize a customer object and randomize its shopping cart
	 */
	public Customer(Bakery bakery) {
		// TODO
		this.bakery = bakery;
		rnd = new Random();
		shoppingCart = new ArrayList();
		fillShoppingCart();
		shopTime = rnd.nextInt(100);
		checkoutTime = rnd.nextInt(100);
	}

	public String getTime() {
		long t = System.currentTimeMillis();
		return new SimpleDateFormat("HH:mm:ss").format(new Date(t).getTime()) + " " + String.format("%5d", t % 60000)
				+ " ";
	}

	/**
	 * Run tasks for the customer
	 */
	public void run() {
		// TODO
		try {
			bakery.mutexPrint.acquire();
			System.out.println(getTime() + "Customer " + String.format("%10d", hashCode()) + "\tbegins");
			bakery.mutexPrint.release();

			for (BreadType bread : shoppingCart) {
				bakery.shelves.get(bread).acquire();
				bakery.takeBread(bread);
				Thread.sleep(shopTime);
				
				bakery.mutexPrint.acquire();
				System.out.println(
						getTime() + "Customer " + String.format("%10d", hashCode()) + "\ttake " + bread.toString());
				bakery.mutexPrint.release();
				
				bakery.shelves.get(bread).release();
			}

			bakery.cashiers.acquire();
			bakery.addSales(getItemsValue());
			Thread.sleep(checkoutTime);
			
			bakery.mutexPrint.acquire();
			System.out.println(getTime() + "Customer " + String.format("%10d", hashCode()) + "\tcheck out "
					+ getItemsValue().toString());
			System.out.println(getTime() + toString());
			bakery.mutexPrint.release();
			
			bakery.cashiers.release();

		} catch (Exception e) {

		}
		

	}

	/**
	 * Return a string representation of the customer
	 */
	public String toString() {
		return "Customer " + String.format("%10d", hashCode()) + "\tends"+":shoppingCart="
				+ Arrays.toString(shoppingCart.toArray()) + ", shopTime=" + shopTime + ", checkoutTime=" + checkoutTime;
	}

	/**
	 * Add a bread item to the customer's shopping cart
	 */
	private boolean addItem(BreadType bread) {
		// do not allow more than 3 items, chooseItems() does not call more than 3 times
		if (shoppingCart.size() >= 3) {
			return false;
		}
		shoppingCart.add(bread);
		return true;
	}

	/**
	 * Fill the customer's shopping cart with 1 to 3 random breads
	 */
	private void fillShoppingCart() {
		int itemCnt = 1 + rnd.nextInt(3);
		while (itemCnt > 0) {
			addItem(BreadType.values()[rnd.nextInt(BreadType.values().length)]);
			itemCnt--;
		}
	}

	/**
	 * Calculate the total value of the items in the customer's shopping cart
	 */
	private BigDecimal getItemsValue() {
		BigDecimal value = new BigDecimal(0);
		for (BreadType bread : shoppingCart) {
			value = value.add(new BigDecimal(Float.toString(bread.getPrice())));
		}
		return value;
	}
}