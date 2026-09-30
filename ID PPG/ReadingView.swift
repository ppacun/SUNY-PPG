// xcode: set sdk=iOS

import SwiftUI

struct ReadingView: View {

    @StateObject private var camera = CameraManager()
    let minRVal = 170
   
    var body: some View {

        VStack(spacing: 20) { //left is top Right is bottom, top is left, +90 deg
            let LVR = (camera.topRed > minRVal), RVR = (camera.bottomRed > minRVal), TVR = (camera.leftRed > minRVal), CVR = (camera.centerRed > minRVal), BVR = (camera.rightRed > minRVal)
            if  CVR && LVR && TVR && RVR && BVR{
                VStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.red)

                    Text("Finger Detected")
                        .font(.largeTitle)
                        .bold()
                }

            }else if (CVR && TVR && LVR && RVR){
                Text("Move Finger Down")
                    .font(.largeTitle)
                    .bold()
            }else if (CVR && BVR && LVR && RVR){
                Text("Move Finger Down")
                    .font(.largeTitle)
                    .bold()
            }else if(TVR && RVR){
                Text("Move Finger Down and Left")
                    .font(.largeTitle)
                    .bold()
            }else if(TVR && LVR){
                Text("Move Finger Down and Right")
                    .font(.largeTitle)
                    .bold()
            }else if(BVR && RVR){
                Text("Move Finger Up and Left")
                    .font(.largeTitle)
                    .bold()
            }else if(BVR && LVR){
                Text("Move Finger Up and Right")
                    .font(.largeTitle)
                    .bold()
            }else if(CVR){
                Text("Move Finger Closer")
                    .font(.largeTitle)
                    .bold()
            }else if(TVR){
                Text("Move Finger Down")
                    .font(.largeTitle)
                    .bold()
            }else if(BVR){// says left
                Text("Move Finger Up")
                    .font(.largeTitle)
                    .bold()
            }else if(LVR){//says UP
                Text("Move Finger Right")
                    .font(.largeTitle)
                    .bold()
            }else if(RVR){
                Text("Move Finger Left")
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

            Text("RGB(\(camera.centerRed), \(camera.centerGreen), \(camera.centerBlue))")
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
