import React from 'react'
import { StyleSheet, Text, View, TouchableOpacity, TextInput, Image, Clipboard, AppState, ActivityIndicator, Linking } from 'react-native'
import PropTypes from 'prop-types'
import Storage from 'app/util/Storage'
import { handleLoginResponseError } from 'app/util/ErrorUtils'
import Api from 'app/Api'
import Base from 'app/style/Base'
import Strings from 'app/style/Strings'
import Icons from 'app/style/Icons'

export default class LoginView extends React.Component {
  static navigationOptions = {
    header: null,
    title: Strings.login.title,
  }

  constructor(props) {
    super(props)
    this.state = {
      appState: AppState.currentState,
      apiToken: null,
      clipboardContent: null,
      loading: false,
    }
  }

  componentDidMount() {
    AppState.addEventListener('change', this.onAppStateChange)
    this.checkClipboardForApiToken()
  }

  componentWillUnmount() {
    AppState.removeEventListener('change', this.onAppStateChange)
  }

  onAppStateChange = (nextAppState) => {
    if (this.state.appState.match(/inactive|background/) && nextAppState === 'active') {
      this.checkClipboardForApiToken()
    }
    this.setState({ appState: nextAppState })
  }

  onChange = (evt) => {
    this.setState({ apiToken: evt.nativeEvent.text })
  }

  onSubmit = async () => {
    this.setState({ loading: true })
    const response = await Api.userToken(this.state.apiToken)
    if (response.ok === 0) {
      this.setState({ loading: false })
      handleLoginResponseError(response.error)
    } else {
      this.setState({ loading: false })
      Storage.setApiToken(this.state.apiToken)
      this.props.navigation.navigate('App')
    }
  }

  onShowToken = () => {
    Linking.openURL('https://m.pinboard.in/settings/password')
  }

  checkClipboardForApiToken = async () => {
    const clipboardContent = await Clipboard.getString()
    this.setState({ clipboardContent: clipboardContent.trim() })
    const regex = /[A-Z,0-9]/g
    const tokenLatterPart = this.state.clipboardContent.split(':')[1]
    if (regex.test(tokenLatterPart) && tokenLatterPart.length === 20) {
      this.setState({ apiToken: this.state.clipboardContent })
    }
  }

  render() {
    return (
      <View style={styles.container}>
        <Image source={Icons.simplepin} style={styles.icon} />
        <Text style={styles.title}>{Strings.login.title}</Text>
        <Text style={styles.text}>{Strings.login.text}</Text>
        <TextInput
          autoCapitalize="none"
          autoCorrect={false}
          enablesReturnKeyAutomatically={true}
          placeholder={Strings.login.placeholder}
          placeholderTextColor = {Base.color.gray2}
          returnKeyType="done"
          secureTextEntry={true}
          style={styles.input}
          textContentType="password"
          underlineColorAndroid="transparent"
          value={this.state.apiToken}
          onChange={this.onChange}
        />
        <TouchableOpacity
          activeOpacity={0.5}
          disabled={!this.state.apiToken}
          style={[styles.loginButton, !this.state.apiToken && styles.disabled]}
          onPress={this.onSubmit}
        >
          <Text style={styles.loginButtonText}>{Strings.login.button}</Text>
        </TouchableOpacity>
        <TouchableOpacity
          activeOpacity={0.5}
          style={styles.tokenButton}
          onPress={this.onShowToken}
        >
          <Text style={styles.tokenButtonText}>{Strings.login.token}</Text>
        </TouchableOpacity>
        <ActivityIndicator style={{ opacity: this.state.loading ? 1 : 0 }} />
      </View>
    )
  }
}

LoginView.propTypes = {
  navigation: PropTypes.object.isRequired,
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    backgroundColor: Base.color.white,
    flex: 1,
    justifyContent: 'center',
    padding: Base.padding.huge,
  },
  icon: {
    marginBottom: Base.padding.medium,
    tintColor: Base.color.blue2,
  },
  title: {
    color: Base.color.gray4,
    fontSize: Base.font.huge,
    fontWeight: Base.font.bold,
    marginBottom: Base.padding.medium,
    textAlign: 'center',
  },
  text: {
    color: Base.color.gray3,
    fontSize: Base.font.medium,
    lineHeight: Base.line.medium,
    marginBottom: Base.padding.large,
    textAlign: 'center',
  },
  input: {
    backgroundColor: Base.color.white,
    borderColor: Base.color.black12,
    borderRadius: Base.radius.medium,
    borderWidth: 1,
    color: Base.color.gray4,
    fontSize: Base.font.medium,
    height: Base.row.medium,
    marginBottom: Base.padding.large,
    textAlign: 'center',
    width: '100%',
  },
  loginButton: {
    backgroundColor: Base.color.blue2,
    borderRadius: Base.radius.medium,
    marginBottom: Base.padding.large,
    paddingHorizontal: Base.padding.medium,
    width: '100%',
  },
  loginButtonText: {
    color: Base.color.white,
    fontSize: Base.font.large,
    fontWeight: Base.font.bold,
    lineHeight: Base.row.medium,
    textAlign: 'center',
  },
  tokenButton: {
    backgroundColor: Base.color.white,
    paddingHorizontal: Base.padding.medium,
    width: '100%',
  },
  tokenButtonText: {
    color: Base.color.gray3,
    fontSize: Base.font.medium,
    lineHeight: Base.row.medium,
    textAlign: 'center',
  },
  disabled: {
    opacity: 0.3,
  },
})
