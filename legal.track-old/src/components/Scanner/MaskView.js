import React from 'react';
import { Platform, Text, TextInput, Image, View, Dimensions, TouchableOpacity, ImageBackground, ScrollView, Animated, Easing, KeyboardAvoidingView, FlatList, Alert } from 'react-native';
import Common from './../../utilities/Common';
import Svg, {
  Circle,
  Defs,
  ClipPath,
  Rect,
  Polygon,
  Path,
  G,
} from 'react-native-svg';

export default class MaskView extends React.Component {

  state = {

  };

  UNSAFE_componentWillMount() {

  }

  constructor(props) {
    super(props);
  }

  render() {

    // let str = "M0,0 l0,"+Common.getLengthByIPhone7(186)+" a20,20 0 0 0 20,20 l80,0 a20,20 0 0 0 20,-20 l0,-80 a20,20 0 0 0 -20,-20 l-80,0 a20,20 0 0 0 -20,20 Z";
    let str = "M0,0 l0,"+Common.getLengthByIPhone7(186)+" a8,8 0 0 0 8,8 l"+Common.getLengthByIPhone7(186)+",0 a8,8 0 0 0 8,-8 l0,-"+Common.getLengthByIPhone7(186)+" a8,8 0 0 0 -8,-8 l-"+Common.getLengthByIPhone7(186)+",0 a8,8 0 0 0 -8,8 Z";

    return (
      <Svg height={Dimensions.get('window').height} width={Dimensions.get('window').width}>
        <Defs>
          <ClipPath id="clip" clipRule={'evenodd'}>
            <Rect x="0" y="0" width="100%" height="100%" />
            <Path
              x={(Common.getLengthByIPhone7(0) - Common.getLengthByIPhone7(186))/2 - 8}
              y={(Dimensions.get('window').height - Common.getLengthByIPhone7(186))/2}
              d={str}
            />
          </ClipPath>
        </Defs>
        <Rect
          x="0"
          y="0"
          width="100%"
          height="100%"
          fill="black"
          opacity="0.2"
          clipPath="url(#clip)"
          clipRule={'evenodd'}
        />
      </Svg>
    );
  }
}
