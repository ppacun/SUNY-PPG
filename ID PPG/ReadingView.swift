// xcode: set sdk=iOS

import SwiftUI

struct ReadingView: View {

    @StateObject private var camera = CameraManager()
    let minRVal = 170
    let maxBVal = 40
    let maxGVal = 100
   
    var body: some View {

        VStack(spacing: 20) { //left is top Right is bottom, top is left, +90 deg
            let LVR = (camera.topRed > minRVal), RVR = (camera.bottomRed > minRVal), TVR = (camera.leftRed  > minRVal), CVR = (camera.centerRed > minRVal), BVR = (camera.rightRed + 10 > minRVal)
            let LVB = (camera.topBlue < maxBVal), RVB = (camera.bottomBlue < maxBVal), TVB = (camera.leftBlue < maxBVal), CVB = (camera.centerBlue < maxBVal), BVB = (camera.rightBlue < maxBVal)
            let LVG = (camera.topGreen < maxGVal), RVG = (camera.bottomGreen < maxGVal), TVG = (camera.leftGreen < maxGVal), CVG = (camera.centerGreen < maxGVal), BVG = (camera.rightGreen < maxGVal)
            let LF = LVR && LVB && LVG, RF = RVR && RVB && RVG, CF = CVR && CVB && CVG, TF = TVR && TVG && TVB, BF = BVR && BVB && BVG
           
            if  (CF && BF && TF && RF && LF){
                VStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.red)

                    Text("Finger Detected")
                        .font(.largeTitle)
                        .bold()
                }

            }else if (CF && TF && LF && RF){
                Image(systemName: "arrow.down")
                    .font(.system(size: 70))
                    .foregroundStyle(.gray)
                
                Text("Move Finger Down")
                    .font(.largeTitle)
                    .bold()
            }else if (CF && BF && LF && RF){
                Image(systemName: "arrow.up")
                    .font(.system(size: 70))
                    .foregroundStyle(.gray)
                
                Text("Move Finger Up")
                    .font(.largeTitle)
                    .bold()
            }else if(TF && RF){
                Image(systemName: "arrow.down.right")
                    .font(.system(size: 70))
                    .foregroundStyle(.gray)
                
                Text("Move Finger Down and Right")
                    .font(.largeTitle)
                    .bold()
            }else if(TF && LF){
                Image(systemName: "arrow.down.left")
                    .font(.system(size: 70))
                    .foregroundStyle(.gray)
                
                Text("Move Finger Down and Left")
                    .font(.largeTitle)
                    .bold()
            }else if(BF && RF){
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 70))
                    .foregroundStyle(.gray)
                
                Text("Move Finger Up and Right")
                    .font(.largeTitle)
                    .bold()
            }else if(BF && LF){
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 70))
                    .foregroundStyle(.gray)
                
                Text("Move Finger Up and left")
                    .font(.largeTitle)
                    .bold()
            }else if(CF){
                Image(systemName: "record.circle")
                    .font(.system(size: 70))
                    .foregroundStyle(.gray)
                
                Text("Move Finger Closer")
                    .font(.largeTitle)
                    .bold()
            }else if(TF){
                Image(systemName: "arrow.down")
                    .font(.system(size: 70))
                    .foregroundStyle(.gray)
                
                Text("Move Finger Down")
                    .font(.largeTitle)
                    .bold()
            }else if(BF){
                Image(systemName: "arrow.up")
                    .font(.system(size: 70))
                    .foregroundStyle(.gray)
                
                Text("Move Finger Up")
                    .font(.largeTitle)
                    .bold()
            }else if(LF){
                Image(systemName: "arrow.left")
                    .font(.system(size: 70))
                    .foregroundStyle(.gray)
                
                Text("Move Finger left")
                    .font(.largeTitle)
                    .bold()
            }else if(RF){
                Image(systemName: "arrow.right")
                    .font(.system(size: 70))
                    .foregroundStyle(.gray)
                
                Text("Move Finger Right")
                    .font(.largeTitle)
                    .bold()
            }
            else {

                Text("Please place finger over camera")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }

            CameraView(session: camera.session)
                .frame(width: 260, height: 260)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.gray, lineWidth: 4)
                )
                .onAppear {
                    camera.turnFlashlightOn()
                }
                .onDisappear {
                    camera.turnFlashlightOff()
                }
            Text("TOP RGB(\(camera.leftRed), \(camera.leftGreen), \(camera.leftBlue))")
                .font(.title3)
                .fontWeight(.bold)
            Text("left RGB(\(camera.topRed), \(camera.topGreen), \(camera.topBlue))" + "Center RGB(\(camera.centerRed), \(camera.centerGreen), \(camera.centerBlue))" + "right RGB(\(camera.bottomRed), \(camera.bottomGreen), \(camera.bottomBlue))")
                .font(.system(size: 10))
                .fontWeight(.bold)
            Text("Bottom RGB(\(camera.rightRed), \(camera.rightGreen), \(camera.rightBlue))")
                .font(.title3)
                .fontWeight(.bold)

            Text("Please remain still")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ReadingView()
    }
}
