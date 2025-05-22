# Fetch Apprenticeship Challenge 2025

## Summary  
This SwiftUI iOS app fetches a JSON feed of recipes and presents them in a clean, navigable list that expands to a corresponding detailed views. Images are downloaded and cached by a custom `ImageLoader` actor that combines in-memory and on-disk caching to keep scrolling smooth and to support basic offline use. Comprehensive unit tests cover both the `APIService` networking layer and the image pipeline, so the core logic remains reliable.  


![IMG_0725](https://github.com/user-attachments/assets/1c9ef546-f16d-44b8-9f13-80241350eaca)
![IMG_0727](https://github.com/user-attachments/assets/43695d6c-d15a-47f4-977e-d4604ec8a6bf)


## Focus Areas  
I concentrated on building the `ImageLoader` because efficient image handling is critical to perceived performance, and I wanted to demonstrate mastery of concurrency and caching without leaning on third-party libraries. I also invested significant effort in unit tests for `APIService` and `ImageLoader`, believing that robust test coverage conveys more long-term value than additional UI flourishes. Together, these two areas ensured that the app would feel fast while remaining easy to maintain.  

## Time Spent  
The project took roughly four hours overall. I spent about an hour and a half designing and coding ImageLoader, an hour building APIService, another hour writing and refining the unit tests, and the remaining minutes on UI construction, JSON decoding, and cleanup.

## Trade-offs and Decisions  
Choosing a custom caching layer over an established library gave me fine-grained control and eliminated external dependencies, but it also meant investing more time in the core logic and less in UI polish. Because the image pipeline directly drives the app’s performance and overall user experience, I prioritized implementing and testing that foundation before adding visual enhancements. 

## Weakest Part  
The user interface, while functional, lacks advanced states such as skeleton loaders, a searchbar, pull-to-refresh, or graceful empty-state messaging. With more time, I would refine those interactions and expose error feedback more clearly to end users.  

## Additional Information  
Concurrency is handled with `async/await`, and `ImageLoader` is isolated in an actor to guarantee thread safety. Tests rely on a custom `StubURLProtocol`, letting them inject any network response without touching production code. If extended, I would add UI tests, implement image prefetching, and enhance offline support, but the current code remains fully runnable and testable as delivered.  
