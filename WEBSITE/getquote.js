document.getElementById('quoteBtn').addEventListener('click', getQuote);

function getQuote(e){
    e.preventDefault();
    var API_URL = 'https://xzroqd8xj8.execute-api.us-east-1.amazonaws.com/serverless_lambda_stage/quote';

    fetch(API_URL, {
        headers:{
            "Content-type": "application/json"
        },
        method: 'GET',
        // body: JSON.stringify(),
        mode: 'cors'
    })
    .then((res) => res.json()) 
    .then(function(data) { 
        console.log(data) 
        quote.textContent = JSON.stringify(data.message);
    })
    .catch(function(err) {
        console.log(err)
    });
}

