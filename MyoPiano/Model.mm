//
//  Model.m
//  MyoPiano
//
//  Created by Pranay Neelagiri on 4/7/18.
//  Copyright © 2018 Pranay Neelagiri. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <tensorflow/core/public/session.h>

#import "Model.h"

tensorflow::GraphDef graph;
tensorflow::Session *session;


@implementation Model


+ (void)loadGraph {

//    NSString *path = [[NSBundle mainBundle] pathForResource:@"inference" ofType:@"pb"];
//
//    if ([self loadGraphFromPath:path] && [self createSession]) {
//        [self predict:maleExample];
//        [self predict:femaleExample];
//        session->Close();
//    }
}

+ (BOOL)loadGraphFromPath:(NSString *)path
{
    auto status = ReadBinaryProto(tensorflow::Env::Default(), path.fileSystemRepresentation, &graph);
    if (!status.ok()) {
        NSLog(@"Error reading graph: %s", path.fileSystemRepresentation);
        return NO;
    }

    // This prints out the names of the nodes in the graph.
    auto nodeCount = (graph).node_size();
    NSLog(@"Node count: %d", nodeCount);
    for (auto i = 0; i < nodeCount; ++i) {
        auto node = (graph).node(i);
        NSLog(@"Node %d: %s '%s'", i, node.op().c_str(), node.name().c_str());
    }

    return YES;
}

+ (BOOL)createSession
{
    tensorflow::SessionOptions options;
    auto status = tensorflow::NewSession(options, &session);
    if (!status.ok()) {
        NSLog(@"Error creating session: %s", status.error_message().c_str());
        return NO;
    }

    status = session->Create(graph);
    if (!status.ok()) {
        NSLog(@"Error adding graph to session: %s", status.error_message().c_str());
        return NO;
    }

    return YES;
}

+ (int)predict:(float *)example
{
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"inference" ofType:@"pb"];
    
    if ([self loadGraphFromPath:path] && [self createSession]) {
        // Define the tensor for the input data. This tensor takes one example
        // at a time, and the example has 20 features.
        tensorflow::Tensor x(tensorflow::DT_FLOAT, tensorflow::TensorShape({ 100, 8 }));
        
        // Put the input data into the tensor.
        auto input = x.tensor<float, 2>();
        for (int i = 0; i < 100; i++) {
            for (int j = 0; j < 8; j++) {
                input(i, j) = example[i * 8 + j];
            }
        }
        
        // The feed dictionary for doing inference.
        std::vector<std::pair<std::string, tensorflow::Tensor>> inputs = {
            {"input", x}
        };
        
        // We want to run these nodes.
        std::vector<std::string> nodes = {
            {"output"}
        };
        
        // The results of running the nodes are stored in this vector.
        std::vector<tensorflow::Tensor> outputs;
        
        // Run the session.
        auto status = session->Run(inputs, nodes, {}, &outputs);
        if (!status.ok()) {
            NSLog(@"Error running model: %s", status.error_message().c_str());
            return -1;
        }
        
        auto result = outputs[0].tensor<float, 2>();
        float max = result(0);
        int maxIndex = 0;
        int i = 1;
        while(i < 6) {
            if(result(i) > max) {
                maxIndex = i;
                max = result(i);
            }
            i++;
        }
        session->Close();
        return maxIndex;
    }
    return -1;
}

+ (int)test {
    return 2001;
}

@end
