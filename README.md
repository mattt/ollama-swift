# Ollama Swift Client

A Swift client library for interacting with the
[Ollama API](https://github.com/ollama/ollama/blob/main/docs/api.md).

## Requirements

- Swift 5.7+
- macOS 13+
- [Ollama](https://ollama.com)

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
.package(url: "https://github.com/mattt/ollama-swift.git", from: "1.0.0")
```

## Usage

> [!NOTE]
> The tests and example code for this library use the
> [llama3.2](https://ollama.com/library/llama3.2) model.
> Run the following command to download the model to run them yourself:
>
> ```
> ollama pull llama3.2
> ```


### Initializing the client

```swift
import Ollama

// Use the default client (http://localhost:11434)
let client = Client.default

// Or create a custom client
let customClient = Client(host: URL(string: "http://your-ollama-host:11434")!, userAgent: "MyApp/1.0")
```

### Generating text

Generate text using a specified model:

```swift
do {
    let response = try await client.generate(
        model: "llama3.2",
        prompt: "Tell me a joke about Swift programming.",
        options: [
            "temperature": 0.7,
            "max_tokens": 100
        ]
    )
    print(response.response)
} catch {
    print("Error: \(error)")
}
```

### Chatting with a model

Generate a chat completion:

```swift
do {
    let response = try await client.chat(
        model: "llama3.2",
        messages: [
            .system("You are a helpful assistant."),
            .user("In which city is Apple Inc. located?")
        ]
    )
    print(response.message.content)
} catch {
    print("Error: \(error)")
}
```

### Generating embeddings

Generate embeddings for a given text:

```swift
do {
    let embeddings = try await client.createEmbeddings(
        model: "llama3.2",
        input: "Here is an article about llamas..."
    )
    print("Embeddings: \(embeddings)")
} catch {
    print("Error: \(error)")
}
```

### Managing models

#### Listing models

List available models:

```swift
do {
    let models = try await client.listModels()
    for model in models {
        print("Model: \(model.name), Modified: \(model.modifiedAt)")
    }
} catch {
    print("Error: \(error)")
}
```

#### Retrieving model information

Get detailed information about a specific model:

```swift
do {
    let modelInfo = try await client.showModel("llama3.2")
    print("Modelfile: \(modelInfo.modelfile)")
    print("Parameters: \(modelInfo.parameters)")
    print("Template: \(modelInfo.template)")
} catch {
    print("Error: \(error)")
}
```

#### Pulling a model

Download a model from the Ollama library:

```swift
do {
    let success = try await client.pullModel("llama3.2")
    if success {
        print("Model successfully pulled")
    } else {
        print("Failed to pull model")
    }
} catch {
    print("Error: \(error)")
}
```

#### Pushing a model

```swift
do {
    let success = try await client.pushModel("mynamespace/mymodel:latest")
    if success {
        print("Model successfully pushed")
    } else {
        print("Failed to push model")
    }
} catch {
    print("Error: \(error)")
}
```
