//#include <metal_stdlib>
//using namespace metal;
//
//struct Ball3 {
//    float2 position;
//    float2 velocity;
//    float4 color;
//    bool isInfectious;
//};
//
//struct SceneConstants {
//    float width;
//    float height;
//    float ballRadius;
//    float deltaTime;
//    uint ballCount;
//    float4 infectiousColor;
//    float4 regularColor;
//};
//
//struct VertexOut {
//    float4 position [[position]];
//    float4 color;
//    float pointSize [[point_size]];
//};
//
//kernel void updateBalls(device Ball3* balls [[buffer(0)]],
//                       constant SceneConstants& constants [[buffer(1)]],
//                       constant int& infectionMode [[buffer(2)]],
//                       uint id [[thread_position_in_grid]]) {
//    if (id >= constants.ballCount) return;
//    
//    device Ball3& ball = balls[id];
//    
//    // Update position
//    ball.position += ball.velocity * constants.deltaTime;
//    
//    // Wall collision
//    if (ball.position.x - constants.ballRadius < 0 || ball.position.x + constants.ballRadius > constants.width) {
//        ball.velocity.x = -ball.velocity.x;
//        ball.position.x = clamp(ball.position.x, constants.ballRadius, constants.width - constants.ballRadius);
//    }
//    
//    if (ball.position.y - constants.ballRadius < 0 || ball.position.y + constants.ballRadius > constants.height) {
//        ball.velocity.y = -ball.velocity.y;
//        ball.position.y = clamp(ball.position.y, constants.ballRadius, constants.height - constants.ballRadius);
//    }
//    
//    // Ball3-ball collision (simple version)
//    for (uint j = 0; j < constants.ballCount; j++) {
//        if (j == id) continue;
//        
//        const float2 otherPos = balls[j].position;
//        const float2 delta = otherPos - ball.position;
//        const float distanceSquared = dot(delta, delta);
//        const float minDistance = constants.ballRadius * 2;
//        
//        if (distanceSquared < minDistance * minDistance) {
//            // Handle infection based on mode
//            if ((infectionMode == 0 && ball.isInfectious && !balls[j].isInfectious) ||
//                (infectionMode == 1 && ball.isInfectious && !balls[j].isInfectious)) {
//                
//                // The atomic operation ensures we don't have race conditions when multiple balls update the same ball
//                atomic_store_explicit((atomic_bool*)&balls[j].isInfectious, infectionMode == 0, memory_order_relaxed);
//                atomic_store_explicit((atomic_bool*)&balls[j].color, constants.infectiousColor, memory_order_relaxed);
//            }
//            
//            // Simple elastic collision
//            float2 collisionNormal = normalize(delta);
//            float2 relativeVelocity = balls[j].velocity - ball.velocity;
//            float impulseMagnitude = dot(relativeVelocity, collisionNormal);
//            
//            if (impulseMagnitude > 0) {
//                float2 impulse = collisionNormal * impulseMagnitude;
//                atomic_fetch_sub_explicit((atomic_float2*)&ball.velocity, impulse, memory_order_relaxed);
//                atomic_fetch_add_explicit((atomic_float2*)&balls[j].velocity, impulse, memory_order_relaxed);
//            }
//            
//            // Push apart to prevent sticking
//            float overlap = minDistance - sqrt(distanceSquared);
//            float2 correction = collisionNormal * overlap * 0.5;
//            atomic_fetch_sub_explicit((atomic_float2*)&ball.position, correction, memory_order_relaxed);
//            atomic_fetch_add_explicit((atomic_float2*)&balls[j].position, correction, memory_order_relaxed);
//        }
//    }
//    
//    // Update color based on infection status
//    ball.color = ball.isInfectious ? constants.infectiousColor : constants.regularColor;
//}
//
//vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
//                             constant Ball3* balls [[buffer(0)]],
//                             constant SceneConstants& constants [[buffer(1)]]) {
//    Ball3 ball = balls[vertexID];
//    
//    VertexOut out;
//    out.position = float4(
//        2.0 * ball.position.x / constants.width - 1.0,
//        1.0 - 2.0 * ball.position.y / constants.height,
//        0.0,
//        1.0
//    );
//    out.color = ball.color;
//    out.pointSize = constants.ballRadius * 2;
//    
//    return out;
//}
//
//fragment float4 fragmentShader(VertexOut in [[stage_in]],
//                              float2 pointCoord [[point_coord]]) {
//    // Make the points circular
//    float2 uv = pointCoord * 2.0 - 1.0;
//    if (length(uv) > 1.0) {
//        discard_fragment();
//    }
//    
//    return in.color;
//}
