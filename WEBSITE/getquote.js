//hitCounter.textContent = 'Submitted. But check the result below!';
// ----------------------------------------
var API_URL = 'https://6s6u2vgo60.execute-api.us-east-1.amazonaws.com/serverless_lambda_stage/quote';

    fetch(API_URL, {
        headers:{
            "Content-type": "application/json"
        },
        method: 'GET',
        // body: JSON.stringify(), // this turns the JS object literal into a JSON string for the API
        mode: 'cors'
    })
    .then((res) => res.json()) // this is making the reply into a json object literal 
    .then(function(data) { 
        console.log(data) 
        quote.textContent = JSON.stringify(data.message);
    })
    .catch(function(err) {
        console.log(err)
    });