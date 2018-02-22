//
//  FlightPlanning.swift
//  FarmLens
//
//  Created by Ian Timmis on 2/22/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import Foundation

class FlightPlanning {
    // Define Infinite (Using INT_MAX caused overflow problems)
    let INF = 10000

    struct Point {
        var x:Int
        var y:Int
    }

    // Given three colinear points p, q, r, the function checks if
    // point q lies on line segment 'pr'
    func onSegment(_ p:Point, _ q:Point, _ r:Point) -> Bool
    {
        if (q.x <= max(p.x, r.x) && q.x >= min(p.x, r.x) &&
            q.y <= max(p.y, r.y) && q.y >= min(p.y, r.y)) {
            return true
        }
        return false
    }

    // To find orientation of ordered triplet (p, q, r).
    // The function returns following values
    // 0 --> p, q and r are colinear
    // 1 --> Clockwise
    // 2 --> Counterclockwise
    func orientation(_ p:Point, _ q:Point, _ r:Point) -> Int
    {
        let val:Int = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
    
        if val == 0 {
          return 0  // colinear
        }
        
        return (val > 0) ? 1: 2 // clock or counterclock wise
    }

    // The function that returns true if line segment 'p1q1'
    // and 'p2q2' intersect.
    func doIntersect(_ p1:Point, _ q1:Point, _ p2:Point, _ q2:Point) -> Bool
    {
        // Find the four orientations needed for general and
        // special cases
        let o1:Int = orientation(p1, q1, p2)
        let o2:Int = orientation(p1, q1, q2)
        let o3:Int = orientation(p2, q2, p1)
        let o4:Int = orientation(p2, q2, q1)
    
        // General case
        if (o1 != o2 && o3 != o4) {
            return true
        }
        
        // Special Cases
        // p1, q1 and p2 are colinear and p2 lies on segment p1q1
        if o1 == 0 && onSegment(p1, p2, q1) {
            return true
        }
    
        // p1, q1 and p2 are colinear and q2 lies on segment p1q1
        if o2 == 0 && onSegment(p1, q2, q1) {
            return true
        }
    
        // p2, q2 and p1 are colinear and p1 lies on segment p2q2
        if o3 == 0 && onSegment(p2, p1, q2) {
            return true
        }
    
        // p2, q2 and q1 are colinear and q1 lies on segment p2q2
        if o4 == 0 && onSegment(p2, q1, q2) {
            return true
        }
    
        return false // Doesn't fall in any of the above cases
    }

    // Returns true if the point p lies inside the polygon[] with n vertices
    func isInside(_ polygon:[Point], _ n:Int, _ p:Point) -> Bool
    {
        // There must be at least 3 vertices in polygon[]
        if (n < 3)  {
            return false
        }
    
        // Create a point for line segment from p to infinite
        let extreme:Point = Point(x:INF, y:p.y)
    
        // Count intersections of the above line with sides of polygon
        var count:Int = 0
        var i:Int  = 0
        
        repeat
        {
            let next:Int = (i+1) % n
    
            // Check if the line segment from 'p' to 'extreme' intersects
            // with the line segment from 'polygon[i]' to 'polygon[next]'
            if doIntersect(polygon[i], polygon[next], p, extreme)
            {
                // If the point 'p' is colinear with line segment 'i-next',
                // then check if it lies on segment. If it lies, return true,
                // otherwise false
                if orientation(polygon[i], p, polygon[next]) == 0 {
                    return onSegment(polygon[i], p, polygon[next])
                }
    
                count = count + 1
            }
            i = next
        } while i != 0
    
        // Return true if count is odd, false otherwise
        return (count % 2 == 1)
    }

    // Driver program to test above functions
    func test()
    {
        let polygon1:[Point] = [Point(x:0, y:0), Point(x:10, y:0), Point(x:10, y:10), Point(x:0, y:10)]
        var n:Int = polygon1.count
        var p:Point = Point(x:20, y:20)
        isInside(polygon1, n, p) ? print("Yes \n") : print("No \n")

        p = Point(x:5,y:5)
        isInside(polygon1, n, p) ? print("Yes \n") : print("No \n")

        let polygon2:[Point] = [Point(x:0, y:0), Point(x:5, y:5), Point(x:5, y:0)]
        p = Point(x:3, y:3)
        n = polygon2.count
        isInside(polygon2, n, p) ? print("Yes \n") : print("No \n")

        p = Point(x:5, y:1)
        isInside(polygon2, n, p) ? print("Yes \n") : print("No \n")

        p = Point(x:8, y:1)
        isInside(polygon2, n, p) ? print("Yes \n") : print("No \n")

        let polygon3:[Point] =  [Point(x:0, y:0), Point(x:10, y:0), Point(x:10, y:10), Point(x:0, y:10)]
        p = Point(x:-1, y:10)
        n = polygon3.count
        isInside(polygon3, n, p) ? print("Yes \n") : print("No \n")
    }
}
