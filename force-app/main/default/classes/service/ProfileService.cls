public with sharing class ProfileService {
    private static ProfileService instance;
    private static Map<String, Profile> profilesMap = new Map<String, Profile>();
    private static boolean isCacheInitialized = false;

    // Static initialization block to pre-load profiles
    static {
        // Check the flag, as static blocks can theoretically be re-triggered in some complex scenarios
        // (like dynamic Apex or Tooling API class recompiles, though unlikely in typical execution).
        // For test methods, clearCache() will reset this, allowing re-initialization.
        if (!isCacheInitialized) {
            initializeCache();
        }
    }

    // Private constructor for Singleton pattern
    private ProfileService() {
    }

    // Private method to initialize the cache
    private static void initializeCache() {
        // Ensure map is clear before initializing, in case this method is ever called again after a partial clear
        profilesMap = new Map<String, Profile>();
        try {
            List<Profile> profiles = [SELECT Id, Name FROM Profile]; // Consider adding IsActive = true if needed
            for (Profile p : profiles) {
                if (p.Name != null) { // Ensure profile name is not null before toLowerCase
                    profilesMap.put(p.Name.toLowerCase(), p);
                }
            }
            isCacheInitialized = true;
        } catch (Exception e) {
            // Log the exception or handle it as per project requirements
            // This could happen if a user doesn't have permission to query Profiles,
            // though it's a basic permission usually available.
            System.debug(LoggingLevel.ERROR, 'Error initializing ProfileService cache: ' + e.getMessage());
            // isCacheInitialized will remain false, and maps will be empty.
            // Public methods should handle profilesMap.isEmpty() gracefully.
        }
    }

    // Static method to get the instance of the service
    // Ensures static block has run.
    public static ProfileService getInstance() {
        if (instance == null) {
            instance = new ProfileService();
        }
        // If cache somehow wasn't initialized by static block (e.g. exception during static init)
        // and we want to retry or ensure it for every getInstance call.
        // However, static block exceptions usually prevent class loading.
        // For robustness in tests where clearCache might be used, we can add a check.
        if (!isCacheInitialized) {
             initializeCache(); // Attempt re-initialization if needed
        }
        return instance;
    }

    /**
     * Retrieves the ID of a Profile by its name from the pre-loaded cache.
     * @param profileName The name of the Profile to retrieve.
     * @return The ID of the Profile, or null if not found or if the cache is not initialized.
     */
    public static Id getProfileId(String profileName) {
        getInstance(); // Ensures static block has run and instance created, and cache initialized.
        if (profileName == null || !isCacheInitialized || profilesMap.isEmpty()) {
            return null;
        }
        Profile p = profilesMap.get(profileName.toLowerCase());
        return p == null ? null : p.Id;
    }

    /**
     * Retrieves the Profile sObject by its name from the pre-loaded cache.
     * @param profileName The name of the Profile to retrieve.
     * @return The Profile sObject, or null if not found or if the cache is not initialized.
     */
    public static Profile getProfile(String profileName) {
        getInstance(); // Ensures static block has run and instance created, and cache initialized.
        if (profileName == null || !isCacheInitialized || profilesMap.isEmpty()) {
            return null;
        }
        return profilesMap.get(profileName.toLowerCase());
    }

    /**
     * Retrieves a clone of the map containing all pre-loaded Profile sObjects.
     * @return A new Map<String, Profile> containing all cached profiles, keyed by lowercase name.
     *         Returns an empty map if the cache is not initialized or empty.
     */
    public static Map<String, Profile> getAllProfiles() {
        getInstance(); // Ensures static block has run and instance created, and cache initialized.
        if (!isCacheInitialized || profilesMap.isEmpty()) {
            return new Map<String, Profile>();
        }
        return profilesMap.clone(); // Return a clone to protect the cache
    }

    /**
     * Utility method primarily for testing to clear the cache and allow re-initialization.
     */
    @TestVisible
    private static void clearCache() {
        profilesMap.clear();
        isCacheInitialized = false;
        // instance = null; // Optional: if singleton re-creation logic needs to be re-tested.
                         // For current design, re-initializing cache is main goal for tests.
    }
}
