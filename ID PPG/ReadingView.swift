// xcode: set sdk=iOS

import SwiftUI

struct ReadingView: View {

    @StateObject private var camera = CameraManager()
    let minRVal = 190
   
    var body: some View {

        VStack(spacing: 20) { //left is top Right is bottom, top is left, +90 deg
            let LVR = (camera.topRed > minRVal), RVR = (camera.bottomRed > minRVal), TVR = ((camera.leftRed + 10) > minRVal), CVR = (camera.centerRed > minRVal), BVR = (camera.rightRed > minRVal)
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
                Image(systemName: "arrow.down")
                    .font(.system(size: 70))
                    .foregroundStyle(.black)
                
                Text("Move Finger Down")
                    .font(.largeTitle)
                    .bold()
            }else if (CVR && BVR && LVR && RVR){
                Image(systemName: "arrow.up")
                    .font(.system(size: 70))
                    .foregroundStyle(.black)
                
                Text("Move Finger Up")
                    .font(.largeTitle)
                    .bold()
            }else if(TVR && RVR){
                Image(systemName: "arrow.down.right")
                    .font(.system(size: 70))
                    .foregroundStyle(.black)
                
                Text("Move Finger Down and Right")
                    .font(.largeTitle)
                    .bold()
            }else if(TVR && LVR){
                Image(systemName: "arrow.down.left")
                    .font(.system(size: 70))
                    .foregroundStyle(.black)
                
                Text("Move Finger Down and Left")
                    .font(.largeTitle)
                    .bold()
            }else if(BVR && RVR){
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 70))
                    .foregroundStyle(.black)
                
                Text("Move Finger Up and Right")
                    .font(.largeTitle)
                    .bold()
            }else if(BVR && LVR){
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 70))
                    .foregroundStyle(.black)
                
                Text("Move Finger Up and left")
                    .font(.largeTitle)
                    .bold()
            }else if(CVR){
                Image(systemName: "record.circle")
                    .font(.system(size: 70))
                    .foregroundStyle(.black)
                
                Text("Move Finger Closer")
                    .font(.largeTitle)
                    .bold()
            }else if(TVR){
                Image(systemName: "arrow.down")
                    .font(.system(size: 70))
                    .foregroundStyle(.black)
                
                Text("Move Finger Down")
                    .font(.largeTitle)
                    .bold()
            }else if(BVR){// says left
                Image(systemName: "arrow.up")
                    .font(.system(size: 70))
                    .foregroundStyle(.black)
                
                Text("Move Finger Up")
                    .font(.largeTitle)
                    .bold()
            }else if(LVR){//says UP
                Image(systemName: "arrow.left")
                    .font(.system(size: 70))
                    .foregroundStyle(.black)
                
                Text("Move Finger left")
                    .font(.largeTitle)
                    .bold()
            }else if(RVR){
                Image(systemName: "arrow.right")
                    .font(.system(size: 70))
                    .foregroundStyle(.black)
                
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
