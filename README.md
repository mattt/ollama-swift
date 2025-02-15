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
.package(url: "https://github.com/mattt/ollama-swift.git", from: "1.1.0")
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

### Using Structured Outputs

You can request structured outputs from models by specifying a format. 
Pass `"json"` to get back a JSON string,
or specify a full [JSON Schema](https://json-schema.org):

```swift
// Simple JSON format
let response = try await client.chat(
    model: "llama3.2",
    messages: [.user("List 3 colors.")],
    format: "json"
)

// Using JSON schema for more control
let schema: Value = [
    "type": "object",
    "properties": [
        "colors": [
            "type": "array",
            "items": [
                "type": "object",
                "properties": [
                    "name": ["type": "string"],
                    "hex": ["type": "string"]
                ],
                "required": ["name", "hex"]
            ]
        ]
    ],
    "required": ["colors"]
]

let response = try await client.chat(
    model: "llama3.2",
    messages: [.user("List 3 colors with their hex codes.")],
    format: schema
)

// The response will be a JSON object matching the schema:
// {
//   "colors": [
//     {"name": "papayawhip", "hex": "#FFEFD5"},
//     {"name": "indigo", "hex": "#4B0082"},
//     {"name": "navy", "hex": "#000080"}
//   ]
// }
```

The format parameter works with both `chat` and `generate` methods.

### Using Tools

Ollama supports tool calling with models,
allowing models to perform complex tasks or interact with external services.

> [!NOTE]
> Tool support requires a [compatible model](https://ollama.com/search?c=tools),
> such as llama3.2.

#### Creating a Tool

Define a tool by specifying its name, description, parameters, and implementation:

```swift
struct WeatherInput: Codable {
    let city: String
}

struct WeatherOutput: Codable {
    let temperature: Double
    let conditions: String
}

let weatherTool = Tool<WeatherInput, WeatherOutput>(
    name: "get_current_weather",
    description: """
    Get the current weather for a city, 
    with conditions ("sunny", "cloudy", etc.)
    and temperature in °C.
    """,
    parameters: [
        "type": "object",
        "properties": [
            "city": [
                "type": "string",
                "description": "The city to get weather for"
            ]
        ],
        "required": ["city"]
    ]
) { input async throws -> WeatherOutput in
    // Implement weather lookup logic here
    return WeatherOutput(temperature: 18.5, conditions: "cloudy")
}
```

#### Using Tools in Chat

Provide tools to the model during chat:

```swift
let messages: [Chat.Message] = [
    .system("You are a helpful assistant that can check the weather."),
    .user("What's the weather like in Portland?")
]

let response = try await client.chat(
    model: "llama3.1",
    messages: messages,
    tools: [weatherTool]
)

// Handle tool calls in the response
if let toolCalls = response.message.toolCalls {
    for toolCall in toolCalls {
        print("Tool called: \(toolCall.function.name)")
        print("Arguments: \(toolCall.function.arguments)")
    }
}
```

#### Multi-turn Tool Conversations

Tools can be used in multi-turn conversations, where the model can use tool results to provide more detailed responses:

```swift
var messages: [Chat.Message] = [
    .system("You are a helpful assistant that can convert colors."),
    .user("What's the hex code for yellow?")
]

// First turn - model calls the tool
let response1 = try await client.chat(
    model: "llama3.1",
    messages: messages,
    tools: [rgbToHexTool]
)

enum ToolError {
    case invalidParameters
}

// Add tool response to conversation
if let toolCall = response1.message.toolCalls?.first {
    // Parse the tool arguments
    guard let args = toolCall.function.arguments,
          let red = Double(redStr, strict: false),
          let green = Double(greenStr, strict: false),
          let blue = Double(blueStr, strict: false) 
    else {
        throw ToolError.invalidParameters
    }
    
    let input = HexColorInput(
        red: red,
        green: green,
        blue: blue
    )
    
    // Execute the tool with the input
    let hexColor = try await rgbToHexTool(input)
    
    // Add the tool result to the conversation
    messages.append(.tool(hexColor))
}

// Continue conversation with tool result
messages.append(.user("What other colors are similar?"))
let response2 = try await client.chat(
    model: "llama3.1",
    messages: messages,
    tools: [rgbToHexTool]
)
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
