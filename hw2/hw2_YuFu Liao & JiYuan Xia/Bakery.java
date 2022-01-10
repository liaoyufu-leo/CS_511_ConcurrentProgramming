import java.math.BigDecimal;
import java.util.Dictionary;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

public class Bakery implements Runnable {
	private static final int TOTAL_CUSTOMERS = 200;
	private static final int ALLOWED_CUSTOMERS = 50;
	private static final int FULL_BREAD = 20;
	private Map<BreadType, Integer> availableBread;
	private ExecutorService executor;
	private BigDecimal sales = new BigDecimal(0);

	// TODO
	// volatile public static HashMap<Integer, Semaphore> cashiers;
	volatile public static Semaphore cashiers = new Semaphore(4, true);
	volatile public static HashMap<BreadType, Semaphore> shelves = new HashMap<>();
	volatile public static Semaphore mutexPrint = new Semaphore(1);

	/**
	 * Remove a loaf from the available breads and restock if necessary
	 */
	public void takeBread(BreadType bread) {
		int breadLeft = availableBread.get(bread);
		if (breadLeft > 0) {
			availableBread.put(bread, breadLeft - 1);
			// System.out.println(bread.toString()+" "+(breadLeft-1));
		} else {
			System.out.println("No " + bread.toString() + " bread left! Restocking...");
			// restock by preventing access to the bread stand for some time
			try {
				Thread.sleep(1000);
			} catch (InterruptedException ie) {
				ie.printStackTrace();
			}
			availableBread.put(bread, FULL_BREAD - 1);
		}
	}

	/**
	 * Add to the total sales
	 */
	public void addSales(BigDecimal value) {
		sales = sales.add(value);
	}

	/**
	 * Run all customers in a fixed thread pool
	 */
	public void run() {
		availableBread = new ConcurrentHashMap<BreadType, Integer>();
		availableBread.put(BreadType.RYE, FULL_BREAD);
		availableBread.put(BreadType.SOURDOUGH, FULL_BREAD);
		availableBread.put(BreadType.WONDER, FULL_BREAD);

		// TODO

		for (BreadType bread : BreadType.values()) {
			shelves.put(bread, new Semaphore(1));
		}
		executor = Executors.newFixedThreadPool(ALLOWED_CUSTOMERS);
		int i = TOTAL_CUSTOMERS;
		while (i > 0) {
			executor.execute(new Customer(this));
			i--;
		}
		executor.shutdown();
		try {
			if (executor.awaitTermination(1, TimeUnit.MINUTES)) {
				System.out.println("Total sales " + sales);
			}
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
}