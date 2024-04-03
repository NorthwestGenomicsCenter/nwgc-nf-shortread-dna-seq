public class Utils {
    // Incomplete
    // TODO: make this work with more than one parameter at a time
	public static Object formatParamsForInclusion(label, value) {
		if(value != null && !value.isEmpty()) {
			return [(label): value]
		}
		return
	}

    public static Object createReadGroupString(String sequencingCenter, String flowcell, String lane, String library, String date, String sample, String readType);
}
